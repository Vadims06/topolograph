# BMP Watcher

**BMP Watcher** amène le plan de contrôle BGP dans Topolograph : les sessions de
peering, les routes qu'elles transportent, le contexte VPN et chaque changement
des deux.

C'est une station [BMP](https://datatracker.ietf.org/doc/html/rfc7854) passive.
Les routeurs ouvrent une session TCP vers elle et poussent leur Adj-RIB-In. Le
watcher ne parle pas BGP, n'établit aucun peering et ne se connecte jamais de
lui-même à un routeur - il n'ajoute donc aucun état BGP au réseau observé.

!!! info "L'état BGP reste séparé de votre graphe IGP"
    Une session BGP est une relation de plan de contrôle, pas un lien de
    transfert. BGP est stocké comme un graphe à part, avec son propre cycle de
    vie, et il est *lié* à vos graphes OSPF et IS-IS, jamais fusionné avec eux.
    Un graphe BGP fonctionne aussi seul, sans aucun graphe IGP.

---

## Ce qui est collecté

### Familles d'adresses

| Famille | AFI | SAFI | Rapportée comme |
|---|---:|---:|---|
| IPv4 unicast | 1 | 1 | `prefix` |
| IPv6 unicast | 2 | 1 | `prefix` |
| VPNv4 | 1 | 128 | `l3vpn` |
| VPNv6 | 2 | 128 | `l3vpn` |
| EVPN | 25 | 70 | `evpn` |

Une route VPN n'est unique qu'avec son Route Distinguisher, le RD fait donc
partie de son identité. Une route EVPN n'a pas de préfixe du tout : elle est
identifiée par les composants NLRI de la RFC 7432 - type de route, Ethernet
Segment ID, Ethernet Tag, MAC, IP.

### Messages BMP

| Message BMP | Ce que Topolograph en fait |
|---|---|
| Route Monitoring | construit la table, puis chaque changement de route |
| Peer Up | état de session et BGP Identifier du pair - le Router ID auquel les événements sont attribués |
| Peer Down | fin de session, plus un withdraw par route que ce pair portait |
| Initiation / Termination | cycle de vie de la session du collecteur |
| Statistics Report | ignoré - les compteurs ne sont pas un état de routage |

### Flux de politique et niveau de preuve

Les deux flux Adj-RIB-In sont stockés séparément et, là où le speaker prend en
charge la [RFC 9069](https://datatracker.ietf.org/doc/html/rfc9069), le flux
Loc-RIB est conservé comme une troisième observation :

| Flux | Preuve | Signification |
|---|---|---|
| `pre` / `out-pre` | `pre_policy` | le pair l'a annoncée ; le routeur a pu la rejeter |
| `post` / `out-post` | `post_policy` | le routeur l'a acceptée - un chemin candidat |
| `loc-rib` | `loc_rib` | le choix propre du routeur - le meilleur chemin installé |
| `fib` | `fib` | présente dans la table de transfert |

Ils ne sont jamais fusionnés. Une route vue uniquement en pre-policy n'est
**jamais** rapportée comme sélectionnée ou installée : cette distinction est la
raison d'être des deux flux.

---

## Installer le collecteur

Pour l'essayer sans réseau réel, lancez le lab containerlab [13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp) du dépôt bmpwatcher.

Le collecteur est [**bmpwatcher**](https://github.com/Vadims06/bmpwatcher), publié
sous forme d'image Docker `vadims06/bmpwatcher:latest` : une station BMP passive à laquelle les
routeurs se connectent en TCP 11019 ; il ne se connecte jamais à un routeur. Il sépare le
rejeu initial de la table des changements qui suivent. Son README couvre la configuration
BMP côté routeur pour FRR, IOS-XR, Junos et SR OS.

Il faut un compte Topolograph : inscrivez-vous sur topolograph.com ou, sur une
instance auto-hébergée, connectez-vous avec l'utilisateur défini dans son `.env` (`TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `TOPOLOGRAPH_WEB_API_PASSWORD`).
Créez un jeton d'API : **API → Token → Create Token**. L'espace de travail est déterminé
à partir du jeton côté serveur et n'est jamais pris dans le payload.

### Lancer avec Docker Compose

Le fichier compose du dépôt bmpwatcher lance ensemble le collecteur et l'expéditeur d'événements Fluent Bit :

```bash
git clone https://github.com/Vadims06/bmpwatcher.git && cd bmpwatcher
cp .env.example .env
docker compose --profile collector up -d
```

Renseignez dans `.env` :

- `TOPOLOGRAPH_HOST` : l'adresse IP de l'hôte Docker, pas `localhost`, car Topolograph et BMP Watcher tournent dans leurs propres réseaux de conteneurs ; `topolograph.com` pour l'instance publique.
- `TOPOLOGRAPH_PORT` : `8080` par défaut, `443` pour topolograph.com.
- `WEBHOOK_TLS_ON` : `off` pour un Topolograph auto-hébergé, `on` pour topolograph.com.
- `TOPOLOGRAPH_API_TOKEN` : le jeton `sk-...`.
- `SOURCE_ID` : le nom de ce collecteur dans Topolograph, par ex. `dc1-rr`. Gardez-le stable : un conteneur recréé avec le même nom garde ses données ensemble.
- `BMPWATCHER_LOG_DIR` : où le collecteur écrit ses fichiers, `/var/log/bmpwatcher` par défaut.

Arrêtez-le avec le même profil : `docker compose --profile collector down`. Activez Docker au démarrage (`systemctl enable docker`) : les conteneurs redémarrent après une panne et un redémarrage.

Le premier instantané part quand chaque routeur a fini de rejouer sa table : environ 30 secondes après l'arrêt de ses routes, au plus 5 minutes après la première. Vérifiez qu'il a été envoyé :

```bash
docker logs bmpwatcher 2>&1 | grep 'topology posted'
```

### EVPN : premiers messages

*Topolograph v2.73 ou ultérieur, BMP Watcher v1.1.0 ou ultérieur. L'export EVPN est vérifié sur FRR.*

Les questions EVPN se posent à votre graphe OSPF ou IS-IS : Topolograph a donc
besoin d'un graphe dont les Router ID correspondent aux speakers BGP.

1. **Obtenez le graphe IGP.** Pour votre réseau, importez sa LSDB ou lancez
   [OSPF Watcher](ospf-watcher.md) / [IS-IS Watcher](isis-watcher.md). Pour le
   lab [13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp), son underlay OSPF est le graphe de
   démonstration à 13 routeurs que Topolograph crée dans chaque compte à la
   première connexion ; pour IS-IS, importez [demo_isis_LSDB.txt](https://github.com/Vadims06/topolograph/blob/master/demo_isis_LSDB.txt) en
   tant que FRR IS-IS.
2. **Activez BMP sur les route reflectors** : ils portent les routes EVPN de
   tous les leaves, alors qu'un leaf n'exporte que ce qu'il a appris. FRR charge
   BMP comme module : ajoutez `-M bmp` à `bgpd_options` et redémarrez FRR :

```
# /etc/frr/daemons
bgpd_options="   --daemon -M bmp -A 127.0.0.1"
```

```
router bgp 65000
 bmp targets topolograph
  bmp connect 198.51.100.10 port 11019 min-retry 1000 max-retry 2000
  bmp monitor l2vpn evpn pre-policy
  bmp monitor l2vpn evpn post-policy
```

Dans containerlab, modifiez le fichier `daemons` du lab puis redéployez-le : redémarrer
FRR dans un conteneur en marche coupe ses liens. Dans `bmp connect`, indiquez une
adresse de l'hôte du collecteur que les routeurs joignent en TCP 11019 ; dans
containerlab, c'est la passerelle du réseau de management du lab
(`docker network inspect <mgmt-network>`).

3. **Démarrez le collecteur** comme ci-dessus.
4. **Vérifiez la réponse sur le graphe IGP** : le graphe dont les `protocols`
   contiennent `bgp`, ses VNI et VRF, et les leaves d'un VNI.

```bash
TOPOLOGRAPH_URL=http://<host-ip>:8080   # https://topolograph.com pour l'instance publique
curl -sS "$TOPOLOGRAPH_URL/api/graph/?protocol=bgp" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
curl -sS "$TOPOLOGRAPH_URL/api/graph/<graph_time>/vpns" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
curl -sS "$TOPOLOGRAPH_URL/api/graph/<graph_time>/nodes?protocol=bgp&vni=<vni>" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
```

Une liste `?protocol=bgp` vide signifie que le graphe BGP n'est pas encore lié :
vérifiez `GET /api/bgp-graph/<bgp_graph_time>/bindings`. La table initiale
arrive dans l'instantané ; le flux d'événements ne porte que les changements
suivants.

Chaque compte contient un graphe BGP de démonstration
capturé sur le lab 13-hosts-demo-bgp et lié au même graphe de démonstration : sur ce
graphe, les réponses incluent donc aussi les routes de démonstration.

---

## Liaison avec vos graphes IGP

Après chaque enregistrement BGP **et** chaque enregistrement IGP, Topolograph
réévalue à quels graphes OSPF ou IS-IS appartient un graphe BGP. Les candidats
sont classés par recouvrement de Router ID via une couverture d'ensembles
gloutonne, si bien qu'un graphe BGP couvrant deux domaines IGP se lie aux deux.

| État | Signification |
|---|---|
| `bound` | recouvrement de Router ID ≥ 80 %, sans ambiguïté |
| `needs_mapping` | sous le seuil, ou deux candidats à égalité - en attente de confirmation |

Un graphe BGP se lie d'abord au graphe IGP en vigueur à son propre instant : le
plus récent qui n'est pas postérieur au graphe BGP. Les snapshots IGP pris
ensuite, tant qu'il reste le graphe BGP le plus récent de sa source, sont liés
aussi, s'ils conservent les routeurs trouvés par la première correspondance. Un
routeur apparu après le snapshot IGP est compté d'après ses événements
d'adjacence OSPF.

Le recouvrement de Router ID est une **preuve, pas une exigence**. Un BGP Router
ID et un OSPF Router ID coïncident généralement, mais Topolograph ne l'impose
jamais : les résultats ambigus restent visibles pour que vous les confirmiez.

```bash
# à quoi un graphe BGP est lié
curl -sS ".../api/bgp-graph/17Aug2026_09h12m03s_6_hosts/bindings" -H "Authorization: Bearer $T"

# confirmer une liaison à la main
curl -sS -X PUT ".../api/bgp-graph/<bgp_graph_time>/<igp_graph_time>/binding" -H "Authorization: Bearer $T"

# en supprimer une
curl -sS -X DELETE ".../api/bgp-graph/<bgp_graph_time>/<igp_graph_time>/binding" -H "Authorization: Bearer $T"
```

!!! note "IS-IS a besoin d'un vrai Router ID"
    En interne, un nœud IS-IS est nommé par un pseudo Router ID forgé par le
    parseur, qui n'existe nulle part sur le réseau. Seul un **TE Router ID**
    annoncé par l'équipement compte comme identité. Un équipement qui n'en
    annonce aucun ne contribue pas au score de recouvrement - c'est le résultat
    honnête, pas un défaut. Activez TE sur l'équipement, ou renseignez le Router
    ID à la main sur la page de **correspondance des noms d'hôtes** ; il migre
    ensuite vers les graphes suivants comme un nom d'hôte.

---

## Interroger les données BGP

### Graphes, nœuds et sessions

```bash
GET /api/bgp-graphs?page=1&per_page=50
GET /api/bgp-graph/{bgp_graph_time}
GET /api/bgp-graph/{bgp_graph_time}/nodes?role=rr&asn=65001
GET /api/bgp-graph/{bgp_graph_time}/sessions?igp_relation=inter-domain&bgp_session_type=ebgp
```

Chaque session est classée dès que les liaisons sont connues :

| `igp_relation` | Signification |
|---|---|
| `intra-domain` | les deux extrémités sont dans le même graphe IGP lié |
| `inter-domain` | les extrémités sont dans deux graphes IGP liés différents |
| `external` | au moins une extrémité n'est dans aucun graphe lié |

`bgp_session_type` vaut `ibgp` ou `ebgp`, déduit de l'ASN de la session comparé à
celui du speaker - et non de `AS_PATH[0]`, qu'une route réfléchie rendrait
trompeur.

### Recherche de routes

```bash
GET /api/bgp-graph/{bgp_graph_time}/routes?prefix=192.0.2.0/24
GET /api/bgp-graph/{bgp_graph_time}/node/{router_id}/routes?evidence=loc_rib
```

| Paramètre | Comportement |
|---|---|
| `prefix=192.0.2.0/24` | correspondance exacte du préfixe complet |
| `prefix=192.0.2.5` | inclusion : toutes les routes couvrant l'adresse, le préfixe le plus long d'abord |
| `mac`, `vni` | EVPN uniquement, voir [EVPN](#evpn) |
| `afi` / `safi` | famille numérique |
| `rd` | Route Distinguisher |
| `vrf` | nom de VRF, résolu vers ses RD via l'inventaire |
| `rt` | n'importe quel Route Target de la route |
| `policy` / `evidence` | flux brut, ou `pre_policy` / `post_policy` / `loc_rib` / `fib` |
| `as_path_contains` | sous-chaîne n'importe où dans l'AS_PATH |
| `community` / `large_community` / `extended_community` | recherche par community |
| `origin`, `local_pref`, `med`, `originator_id`, `label` | filtres d'attributs |
| `peer_ip`, `nexthop`, `bmp_source` | qui l'a annoncée et comment elle est jointe |
| `page`, `per_page` | pagination (`per_page` plafonné à 500) |

Chaque route porte VRF/RD/RT, AFI/SAFI, politique et preuve, path ID,
communities, next hop, labels et origin.

### Historique et comparaison

```bash
# état de la table maintenant, ou tel qu'il était à un instant donné
GET /api/bgp-graph/{bgp_graph_time}/routes/state
GET /api/bgp-graph/{bgp_graph_time}/routes/state?at=2026-08-17T09:20:00Z

# ce qui a changé entre deux instants
GET /api/bgp-graph/{bgp_graph_time}/routes/compare?t0=...&t1=...

# le flux d'événements et les couloirs de la timeline de supervision
GET /api/bgp-graph/{bgp_graph_time}/events?last_minutes=60&event_name=peer
GET /api/bgp-graph/{bgp_graph_time}/events/timeline
```

`state` sans `at` lit une vue courante maintenue en continu : le coût est celui
de la réponse, pas d'un rejeu de tout le journal d'événements. Un `at` explicite
rejoue les deltas depuis la base de l'instantané jusqu'à cet instant. Les bornes
temporelles sont inclusives des deux côtés.

`compare` renvoie une ligne par changement : `added`, `withdrawn` ou `changed`
avec l'avant et l'après.

Sur la timeline de supervision, `bgp_peer` reçoit un marqueur par montée ou chute
de session - faible volume, et chaque flap compte - tandis que `bgp_route` est
regroupé : une rafale de churn de routes s'affiche en un seul marqueur avec un
compteur, et non en milliers de points.

### Route lookup

Le route lookup répond à « que fait réellement ce routeur de cette
destination ? », par opposition à un SPF purement topologique.

```bash
GET /api/graph/{graph_time}/route-lookup/{start_node}?destination=192.0.2.5&vrf=Red&with_lsps=1
```

```json
{
  "prefix": "192.0.2.0/24",
  "start_node": "10.0.0.1",
  "route_source": "BGP",
  "admin_distance": 200,
  "nexthop": "10.0.0.9",
  "resolution_chain": ["192.0.2.0/24", "10.0.0.9/32"],
  "path_segments": [{"domain": "17Aug2026_09h05m00s_6_hosts",
                     "path": ["10.0.0.1", "10.0.0.4", "10.0.0.9"]}],
  "warning": null
}
```

L'ordre de décision est délibéré :

1. **Plus long préfixe correspondant** dans la table ou la VRF choisie.
2. **Sélection du meilleur chemin BGP** - un chemin par préfixe, sur LOCAL_PREF,
   longueur d'AS_PATH, ORIGIN et MED, avant toute comparaison entre protocoles.
   Une observation Loc-RIB clôt la comparaison : c'est le choix du routeur
   lui-même.
3. **Distance administrative** entre les candidats survivants de protocoles
   différents.
4. **Résolution récursive du next hop**, protégée contre les boucles et la
   profondeur.
5. **Transport IGP SPF/CSPF** vers ce next hop, éventuellement par des raccourcis
   LSP éligibles.

| Protocole | AD |
|---|---:|
| connected | 0 |
| static | 1 |
| eBGP | 20 |
| OSPF | 110 |
| IS-IS | 115 |
| iBGP | 200 |

La distance administrative appartient aux **routes**, jamais aux arêtes de la
topologie. Les métriques d'OSPF, d'IS-IS et de BGP ne sont jamais comparées entre
elles : une métrique n'a de sens qu'à l'intérieur de son propre protocole. iBGP
ou eBGP est déterminé par la session sur laquelle la route a été apprise, pas par
`AS_PATH[0]`.

Les routes candidates sont limitées à ce que le nœud de départ voit réellement :
sa propre table rapportée plus celles de ses voisins de session directs. Un
routeur qui ne fait pas de BGP n'hérite de rien.

## EVPN

*Topolograph v2.73 ou ultérieur, BMP Watcher v1.1.0 ou ultérieur.*

BGP EVPN sur VXLAN (AFI 25 / SAFI 70) est lu dans le flux BMP des route
reflectors. Toute question EVPN se pose à votre graphe OSPF ou IS-IS : le
graphe BGP qui lui est lié y répond, et chaque VTEP est résolu vers le routeur
qui possède l'adresse, si bien qu'un chemin vers un hôte s'arrête au leaf
derrière lequel il se trouve.

### Types de route

| Type de route | RFC | Sert à |
|---|---|---|
| 1 Ethernet Auto-Discovery | [RFC 7432](https://datatracker.ietf.org/doc/html/rfc7432) | stockée et consultable |
| 2 MAC/IP Advertisement | RFC 7432 | où se trouve un hôte : MAC, IP, VNI, VTEP, ESI ; déplacements de MAC |
| 3 Inclusive Multicast Ethernet Tag | RFC 7432, [RFC 6514](https://datatracker.ietf.org/doc/html/rfc6514) | quels leaves sont VTEP d'un VNI (le VNI vient de l'attribut PMSI Tunnel) |
| 4 Ethernet Segment | RFC 7432 | stockée et consultable |
| 5 IP Prefix | [RFC 9136](https://datatracker.ietf.org/doc/html/rfc9136) | sous-réseaux d'une VRF et son L3VNI |

### Attributs de route

Une route EVPN porte les habituels RD, route targets, next hop et communities,
plus un objet `evpn` :

| Champ | Signification |
|---|---|
| `route_type` | de 1 à 5 |
| `mac` | MAC de l'hôte (RT-2) |
| `ip`, `ip_len` | IP de l'hôte (RT-2), préfixe et sa longueur (RT-5), routeur d'origine (RT-3, RT-4) |
| `vni` | L2VNI (RT-2, RT-3) |
| `l3vni` | L3VNI de la VRF (RT-5, et RT-2 en symmetric IRB) |
| `esi` | Ethernet Segment ID ; que des zéros signifie un hôte relié à un seul leaf |
| `eth_tag` | Ethernet Tag ID |
| `vtep` | le VTEP : le routeur d'origine pour RT-3 et RT-4, le next hop pour les autres |
| `mm_seq` | numéro de séquence MAC Mobility ([RFC 7432 §15](https://datatracker.ietf.org/doc/html/rfc7432#section-15)) |

Pour RT-2 et RT-5, `prefix` est aussi renseigné (l'adresse de l'hôte en /32 ou
/128, ou le préfixe RT-5), donc `prefix=` trouve les hôtes et sous-réseaux EVPN
comme n'importe quelle autre route.

```json
{
  "afi": 25, "safi": 70, "rd": "1:123.123.31.31:5",
  "route_targets": ["65000:1020"], "nexthop": "123.123.31.31",
  "evpn": {"route_type": 2, "mac": "00:c1:ab:00:00:03", "ip": null, "ip_len": null,
           "vni": 1020, "l3vni": null, "esi": "00:00:00:00:00:00:00:00:00:00",
           "eth_tag": 0, "vtep": "123.123.31.31", "mm_seq": null}
}
```

### Questions auxquelles il répond

Toutes se posent au graphe IGP (`{graph_time}`), sans l'instant du graphe BGP.

| Question | Requête |
|---|---|
| Quels VNI et VRF la fabric a-t-elle ? | `GET /api/graph/{graph_time}/vpns` |
| Quels VPN un routeur voit-il ? | `GET /api/graph/{graph_time}/node/{router_id}/vpns` |
| Quels leaves portent le VNI 1020 ou la VRF tenant1 ? | `GET /api/graph/{graph_time}/nodes?protocol=bgp&vni=1020` (ou `vrf=tenant1`) |
| Où est un hôte : leaf, VNI, VRF, MAC ? | `GET /api/graph/{graph_time}/routes?prefix=10.10.20.13` ou `?mac=00:c1:ab:00:00:03` |
| L'hôte est-il multihomed ? | la même requête : plusieurs VTEP avec un même `esi` non nul |
| Que route une VRF ? | `GET /api/graph/{graph_time}/routes?vrf=tenant1` |
| Que contient un leaf pour un VNI ? | `GET /api/graph/{graph_time}/node/{router_id}/routes?vni=1010` |
| Un MAC a-t-il bougé, de quel leaf vers lequel, quand ? | `GET /api/events/{graph_time}/routes?mac=00:c1:ab:00:00:01&last_minutes=60` |
| Comment l'underlay atteint-il tous les VTEP d'un VNI ? | `GET /api/graph/{graph_time}/path/{node_a}/{vtep1},{vtep2}` |

`routes` accepte aussi `at=` pour un instant passé, ainsi que `vtep=`, `rt=`,
`rd=`, `page`, `per_page`. Dans l'historique des événements, la ligne où un MAC
apparaît sur un nouveau VTEP porte `moved_from_vtep`. Le même MAC annoncé par
plusieurs VTEP sous un même ESI relève du multihoming, pas d'un déplacement.

Une ligne VPN regroupe les routes par nom de VRF quand l'inventaire des VRF le
connaît, sinon par route target ; un bridge domain EVPN fait une ligne par
L2VNI :

```json
{"name": null, "vni": 1020, "l3vni": 5000,
 "route_targets": ["65000:1020", "65000:5000"],
 "route_distinguishers": ["1:123.123.30.30:5", "1:123.123.31.31:5"],
 "prefix_count": 4}
```

Dans l'interface, les mêmes réponses se trouvent dans le formulaire de chemin
BGP / VPN et dans Graph table, BGP Routes, qui a une colonne pour chaque champ
ci-dessus. Un pas-à-pas sur les données de démonstration est dans le
[BGP how-to](https://topolograph.com/how-to/bgp#evpn), et le lab sur lequel elles ont été capturées est
[containerlab/13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp).

---

## Limites actuelles

- EVPN suppose des VNI globaux à toute la fabric : les VNI à portée locale
  (RFC 8365) ne sont pas pris en charge.
- Le choix du designated forwarder d'un Ethernet Segment se fait sur les leaves
  et n'est pas transmis par BMP.
- Un Router ID présent légitimement dans deux domaines IGP liés est rattaché à
  l'un d'eux pour la classification des sessions.

---

## Voir aussi

- [bmpwatcher sur GitHub](https://github.com/Vadims06/bmpwatcher)
- [OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)
- [Événements, timeline et statut](events-timeline.md)
- [Session BGP-LS](../ingestion/bgp-ls.md) - BGP-LS transporte la topologie
  *IGP*, un sujet différent de l'état de routage BGP décrit ici

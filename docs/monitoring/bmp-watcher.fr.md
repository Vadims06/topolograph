# BMP Watcher

**BMP Watcher** amène le plan de contrôle BGP dans Topolograph : les sessions de
peering, les routes qu'elles transportent, le contexte VPN et chaque changement
des deux.

C'est une station [BMP](https://datatracker.ietf.org/doc/html/rfc7854) passive.
Les routeurs ouvrent une session TCP vers elle et poussent leur Adj-RIB-In. Le
watcher ne parle pas BGP, n'établit aucun peering et ne se connecte jamais de
lui-même à un routeur — il n'ajoute donc aucun état BGP au réseau observé.

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
identifiée par les composants NLRI de la RFC 7432 — type de route, Ethernet
Segment ID, Ethernet Tag, MAC, IP.

### Messages BMP

| Message BMP | Ce que Topolograph en fait |
|---|---|
| Route Monitoring | construit la table, puis chaque changement de route |
| Peer Up | état de session et BGP Identifier du pair — le Router ID auquel les événements sont attribués |
| Peer Down | fin de session, plus un withdraw par route que ce pair portait |
| Initiation / Termination | cycle de vie de la session du collecteur |
| Statistics Report | ignoré — les compteurs ne sont pas un état de routage |

### Flux de politique et niveau de preuve

Les deux flux Adj-RIB-In sont stockés séparément et, là où le speaker prend en
charge la [RFC 9069](https://datatracker.ietf.org/doc/html/rfc9069), le flux
Loc-RIB est conservé comme une troisième observation :

| Flux | Preuve | Signification |
|---|---|---|
| `pre` / `out-pre` | `pre_policy` | le pair l'a annoncée ; le routeur a pu la rejeter |
| `post` / `out-post` | `post_policy` | le routeur l'a acceptée — un chemin candidat |
| `loc-rib` | `loc_rib` | le choix propre du routeur — le meilleur chemin installé |
| `fib` | `fib` | présente dans la table de transfert |

Ils ne sont jamais fusionnés. Une route vue uniquement en pre-policy n'est
**jamais** rapportée comme sélectionnée ou installée : cette distinction est la
raison d'être des deux flux.

### Des observations, pas des sous-réseaux

Le même préfixe est stocké une fois par speaker, une fois par pair, une fois par
path ID et une fois par flux de politique. Toutes les copies survivent, parce que
« qui a annoncé quoi à qui » est exactement la question à laquelle répond une
table supervisée.

---

## Installer le collecteur

Le collecteur est [**bmpwatcher**](https://github.com/Vadims06/bmpwatcher), une
station BMP en Go qui sépare le rejeu initial de la table des changements qui
suivent. Son README couvre la compilation, l'exécution sous Docker et la
configuration BMP côté routeur pour FRR, IOS-XR, Junos et SR OS.

Exécution minimale, produisant à la fois l'instantané et le flux d'événements :

```bash
bmpwatcher \
  --bmp-port=11019 \
  --source-id=pe1 \
  --watcher-name=bmp-dc1 \
  --events=/var/log/bmpwatcher/events.jsonl \
  --topolograph-topology-url=https://topolograph.com/api/watcher/bgp
```

!!! warning "L'authentification n'est pas encore câblée dans le collecteur"
    `/api/watcher/bgp` exige `Authorization: Bearer sk-...`, et le collecteur
    n'ajoute pas encore cet en-tête — un envoi direct reçoit `401`. En attendant,
    écrivez le document en local avec `--topolograph-topology-file` et postez-le
    vous-même (voir l'exemple `curl` ci-dessous).

Le jeton se crée dans **Settings → API Tokens → Create token**. L'espace de
travail est résolu à partir du jeton côté serveur et n'est jamais lu dans le
payload.

---

## API d'ingestion

### `POST /api/watcher/bgp` — l'instantané de topologie

Le collecteur assemble toute la table pendant sa fenêtre de collecte et l'envoie
en un seul document.

```bash
curl -sS -X POST https://topolograph.com/api/watcher/bgp \
  -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data @topolograph-topology.json
```

```json
{
  "time": "2026-08-17T09:12:03Z",
  "user": "bmp-dc1",
  "srcid": "pe1",
  "sesid": "b4f1c8e2",
  "topology": {
    "nodes": [
      {"name": "10.0.0.1", "asn": "65001", "role": "speaker", "router_ip": "10.0.0.1"},
      {"name": "10.0.0.2", "asn": "65002", "role": "peer"}
    ],
    "edges": [
      {"source": "10.0.0.1", "target": "10.0.0.2",
       "peer_ip": "10.0.0.2", "local_ip": "10.0.0.1", "asn": "65002",
       "peer_type": 0, "policies": ["pre", "post"], "families": ["1/1", "1/128"]}
    ],
    "networks": [
      {"subnet": "192.0.2.0/24", "type": "1", "subtype": 1,
       "bmp_source": "10.0.0.1", "peer_ip": "10.0.0.2",
       "policy": ["post"], "path_id": 0, "nexthop": "10.0.0.2",
       "vpn_rd": "65001:100", "rt": "65001:100",
       "labels": [24001], "data": {}}
    ]
  }
}
```

| Champ | Signification |
|---|---|
| `time` | horodatage de l'instantané, ISO 8601 — également la clé d'obsolescence |
| `srcid` | l'instance du collecteur |
| `sesid` | une *exécution* du collecteur ; change à chaque redémarrage |
| `nodes[].role` | `speaker` rapporte ; `peer` a seulement été rapporté |
| `edges[]` | une **session** BGP, pas une paire de routeurs |
| `networks[]` | une **observation** de route |
| `networks[].type` / `subtype` | AFI en chaîne, SAFI en nombre |
| `networks[].data` | l'enregistrement brut du collecteur, pour qu'aucun attribut non promu ne soit perdu |

**Réponse**

```json
{"graph_time": "17Aug2026_09h12m03s_6_hosts", "checkpoint": false, "routes": 1428}
```

`graph_time` est l'identifiant public utilisé par tous les endpoints de lecture
ci-dessous — le même format que les graphes IGP.

**Ordre et renvois.** Le `sesid` est créé au démarrage du collecteur, exactement
au moment où les speakers rejouent leurs tables. Dans un même `sesid`, le `time`
le plus récent l'emporte ; un plus ancien ou égal est rejeté avec
`400 stale snapshot`. Un renvoi complet périodique sous le même `sesid` est
traité comme un **point de contrôle de réconciliation**, pas comme un nouveau
graphe : il renvoie `checkpoint: true`, prouve que la source est vivante sur un
réseau silencieux et corrige la vue courante si elle a dérivé. Un nouveau `sesid`
remplace l'exécution précédente.

Tous les Route Targets sont extraits de `data.base_attrs.ext_community_list`, et
pas seulement du champ `rt` promu — une route portant plusieurs RT reste visible
pour une recherche sur n'importe lequel d'entre eux.

### `POST /api/watcher/bgp/events` — le flux de changements

Accepte un objet d'événement ou une liste.

```bash
curl -sS -X POST https://topolograph.com/api/watcher/bgp/events \
  -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '[{
        "srcid": "pe1", "sesid": "b4f1c8e2", "seq": 41,
        "watcher_time": "2026-08-17T09:14:11Z",
        "event_name": "prefix", "event_status": "withdraw",
        "event_object": "192.0.2.0/24", "event_detected_by": "10.0.0.2",
        "bmp_source": "10.0.0.1", "policy": "post",
        "afi": 1, "safi": 1, "prefix": "192.0.2.0", "prefix_len": 24,
        "family_data": {"peer_ip": "10.0.0.2"}
      }]'
```

| Champ | Signification |
|---|---|
| `event_name` | `prefix`, `l3vpn`, `evpn`, `peer` |
| `event_status` | `add`, `change`, `withdraw` (routes) ; `up`, `down` (pairs) |
| `event_detected_by` | le routeur concerné par le changement |
| `bmp_source` | le speaker qui l'a rapporté — un autre routeur sur toute session réfléchie |
| `seq` | monotone par `sesid` ; déduplication exacte et détection de trous |
| `watcher_time` | horloge du collecteur — ordonne le flux |
| `bmp_timestamp` | horloge du routeur — corrélation seulement, jamais l'ordre |
| `replay_suspect` | peut être la queue d'un rejeu plutôt qu'un changement réel |

```json
{"accepted": 1, "duplicates": 0}
```

Un événement dont le couple `(srcid, sesid)` ne correspond à aucun instantané
stocké est rejeté — **envoyez la topologie avant de démarrer le flux
d'événements**. Un `seq` répété est compté comme doublon et écarté ; un trou dans
`seq` est journalisé comme message perdu.

Un événement peer up/down est purement informatif. Le collecteur émet déjà un
withdraw ordinaire par préfixe pour chaque route que le pair tombé portait ;
l'événement de pair lui-même ne modifie donc jamais l'état des routes.

### `POST /api/watcher/vrfs` — inventaire des VRF

Les Route Distinguishers identifient les routes VPN, mais seul l'équipement
connaît le *nom* de la VRF et ses Route Targets d'import/export. Publier
l'inventaire permet de chercher par nom de VRF plutôt que par RD.

```bash
curl -sS -X POST https://topolograph.com/api/watcher/vrfs \
  -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
        "router_id": "10.0.0.1",
        "observed_at": "2026-08-17T09:10:00Z",
        "vrfs": [{
          "name": "Red",
          "families": [{
            "afi": "ipv4", "safi": "unicast",
            "route_distinguisher": "65001:100",
            "import_route_targets": ["65001:100", "65001:999"],
            "export_route_targets": ["65001:100"]
          }]
        }]
      }'
```

Chaque observation est stockée avec son propre horodatage au lieu d'écraser la
précédente, si bien qu'un graphe plus ancien peut toujours reconstituer l'état de
la VRF tel qu'il était alors. L'unicité est `(espace de travail, router_id, rd)` ;
un renvoi identique n'écrit rien.

---

## Liaison avec vos graphes IGP

Après chaque enregistrement BGP **et** chaque enregistrement IGP, Topolograph
réévalue à quels graphes OSPF ou IS-IS appartient un graphe BGP. Les candidats
sont classés par recouvrement de Router ID via une couverture d'ensembles
gloutonne, si bien qu'un graphe BGP couvrant deux domaines IGP se lie aux deux.

| État | Signification |
|---|---|
| `bound` | recouvrement de Router ID ≥ 80 %, sans ambiguïté |
| `needs_mapping` | sous le seuil, ou deux candidats à égalité — en attente de confirmation |

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
    annonce aucun ne contribue pas au score de recouvrement — c'est le résultat
    honnête, pas un défaut. Activez TE sur l'équipement, ou renseignez le Router
    ID à la main sur la page de **correspondance des noms d'hôtes** ; il migre
    ensuite vers les graphes suivants comme un nom d'hôte.

---

## Relire les données

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
celui du speaker — et non de `AS_PATH[0]`, qu'une route réfléchie rendrait
trompeur.

### Recherche de routes

```bash
GET /api/bgp-graph/{bgp_graph_time}/routes?prefix=192.0.2.0/24
GET /api/bgp-graph/{bgp_graph_time}/node/{router_id}/routes?evidence=loc_rib
```

| Paramètre | Comportement |
|---|---|
| `prefix=192.0.2.0/24` | correspondance exacte du préfixe complet |
| `prefix=192.0.2.5` | inclusion — toutes les routes couvrant l'adresse |
| `prefix=192.0.2.0/24&lpm=1` | plus long préfixe correspondant, une ligne |
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
de session — faible volume, et chaque flap compte — tandis que `bgp_route` est
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
2. **Sélection du meilleur chemin BGP** — un chemin par préfixe, sur LOCAL_PREF,
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

---

## Rétention

Topolograph conserve les graphes BGP les plus récents **par source** (`srcid`),
si bien qu'une installation avec deux collecteurs garde une fenêtre complète pour
chacun. Quand une époque sort de la fenêtre, ses routes et ses liaisons partent
avec elle. Les renvois périodiques sous le même `sesid` sont des points de
contrôle et ne consomment pas la fenêtre.

---

## Limites actuelles

- Le collecteur n'attache pas encore le jeton d'API ; postez l'instantané avec
  `curl` en attendant.
- Lancez un collecteur par speaker BMP et définissez `--source-id`. Plusieurs
  speakers vers un seul collecteur mélangent leurs observations.
- Les routes EVPN sont collectées et stockées, mais la table de routes et le
  route lookup sont orientés préfixe ; EVPN n'est pas encore un sujet de
  recherche de premier ordre.
- Un Router ID présent légitimement dans deux domaines IGP liés est rattaché à
  l'un d'eux pour la classification des sessions.

---

## Voir aussi

- [bmpwatcher sur GitHub](https://github.com/Vadims06/bmpwatcher)
- [OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)
- [Événements, timeline et statut](events-timeline.md)
- [Session BGP-LS](../ingestion/bgp-ls.md) — BGP-LS transporte la topologie
  *IGP*, un sujet différent de l'état de routage BGP décrit ici

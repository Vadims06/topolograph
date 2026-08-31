# OSPF Watcher

**OSPF Watcher** est un outil de surveillance des changements de topologie
OSPF. Il écoute passivement le plan de contrôle OSPF — via une
[adjacence GRE](../ingestion/gre.md) ou [BGP-LS](../ingestion/bgp-ls.md) —
et enregistre chaque changement et/ou l'exporte (via Logstash ou Fluent
Bit) vers **ELK**, **Zabbix**, les **WebHooks**, et le tableau de bord de
surveillance de **Topolograph**. Tout est livré sous forme de conteneurs,
donc le démarrage est rapide.

[:simple-github: vadims06/ospfwatcher](https://github.com/Vadims06/ospfwatcher){ .md-button }

![Architecture OSPF Watcher + Topolograph avec règles XDP](../assets/ospfwatcher_architecture.png)

## Événements détectés

- Adjacence de voisin OSPF **en service/hors service**
- **Changements de coût** de lien OSPF
- Réseaux OSPF **apparaissant/disparaissant**
- **Attributs TE** OSPF (via LSA opaque ou BGP-LS) : groupe administratif,
  bande passante maximale du lien, bande passante réservable maximale,
  bande passante non réservée, métrique TE par défaut, et groupe de liens
  à risque partagé (SRLG)
- **Changements de rôle de nœud** OSPF : un routeur devenant (ou cessant
  d'être) un **ABR** (Area Border Router), un **ASBR** (AS Boundary
  Router), ou entrant/sortant du **max-metric** (RFC 3137, routeur stub —
  tous les liens de transit annoncés à la métrique maximale pour détourner
  le trafic de transit ; l'équivalent OSPF du bit overload d'IS-IS)

![Surveillance OSPF — événement de nouveau sous-réseau](../assets/ospf_monitoring_new_subnet.png)

![Surveillance OSPF — changement de métrique, ancien et nouveau coût](../assets/ospf_monitoring_change_metric.png)

![Surveillance OSPF — événements de lien en service/hors service sur la chronologie](../assets/ospf_monitoring_down_link.png)

## Le connecter

La connexion elle-même est mise en place sous
[Importer la topologie](../ingestion/index.md) :

- [**Mode GRE**](../ingestion/gre.md) — FRR établit une adjacence OSPF via
  un tunnel GRE. Un **filtre XDP OSPF** garantit que le Watcher reste en
  écoute seule.
- [**Mode BGP-LS**](../ingestion/bgp-ls.md) — le routeur exporte la
  topologie OSPF via BGP-LS ; GoBGP + le forwarder alimentent le Watcher.
  Nécessite l'image **`vadims06/ospf-watcher:v3.1.0`** ou plus récente.

!!! note "Compatibilité"
    Les changements de réseau OSPF apparaissent sur le graphe Topolograph à
    partir de
    [topolograph v2.27](https://github.com/Vadims06/topolograph/releases/tag/v2.27)
    ou ultérieur.

## Laboratoire rapide (containerlab) { #quick-lab-containerlab }

Un laboratoire prêt à l'emploi sous `containerlab/frr01` vous permet
d'observer les changements OSPF sans aucun matériel réel :

```bash
./containerlab/frr01/prepare.sh
sudo clab deploy --topo ./containerlab/frr01/frr01.clab.yml
```

![Logs du laboratoire containerlab OSPF Watcher](../assets/ospfwatcher_containerlab.png)

Dans cette configuration minimale, le Watcher imprime les changements de
topologie dans un fichier texte. Ajoutez Topolograph et/ou ELK pour les
visualiser et les rechercher — voir la table des
[tailles de déploiement](index.md#deployment-sizes).

!!! tip "Pas d'équipement ? Mode test"
    Définissez `TEST_MODE=True` pour rejouer une LSDB de démonstration et
    des événements d'exemple (perte d'adjacence, changement de métrique) de
    bout en bout à travers le pipeline.

## Format du journal d'événements { #event-log-format }

Les événements du Watcher sont de simples lignes séparées par des virgules.
Un événement d'hôte (adjacence) :

```text
2023-01-01T00:00:00Z,demo-watcher,host,10.10.10.4,down,10.10.10.5,01Jan2023_00h00m00s_7_hosts,0,1234,192.168.145.5
```

> `10.10.10.5` a détecté que l'hôte `10.10.10.4`, sur l'interface avec
> `192.168.145.5`, dans la zone `0` / AS `1234`, est passé **hors
> service** à l'horodatage indiqué.

Un événement de changement de métrique :

```text
2023-01-01T00:00:00Z,demo-watcher,network,192.168.13.0/24,changed,old_cost:10,new_cost:12,10.10.10.1,01Jan2023_00h00m00s_7_hosts,0.0.0.0,1234,internal,0
```

> `10.10.10.1` a détecté que la métrique du réseau stub interne
> `192.168.13.0/24` est passée de `10` à `12`.

Un événement de changement d'indicateur de nœud :

```text
2023-01-01T00:00:00Z,demo-watcher,node,10.1.1.3,changed,attr:abr,old:0,new:1,10.1.1.3,01Jan2023_00h00m00s_7_hosts,0,1234
```

> `10.1.1.3` s'est annoncé comme **ABR** (`abr` `0` → `1`). Un événement
> est émis par indicateur modifié (`abr`, `asbr`, `maxmetric` pour OSPF ;
> `overload`, `attached` pour IS-IS). Entrer en max-metric émet aussi un
> événement `metric` par lien, puisque le coût de chaque lien de transit
> saute à son maximum.

Ces enregistrements sont ce que Logstash/Fluent Bit transmettent vers
[ELK](elk-kibana.md), [Zabbix](zabbix.md) et [Webhooks](webhooks.md).

## Mode écoute seule (XDP) { #listen-only-mode-xdp }

En mode GRE, le Watcher exécute une véritable instance FRR — il est donc
essentiel qu'il ne puisse **jamais** injecter de préfixes dans votre
domaine OSPF. Un **filtre XDP** inspecte chaque message OSPF que FRR tente
d'envoyer et rejette tout ce qui annonce plus que le réseau du tunnel GRE
du Watcher lui-même.

![Wireshark avant/après le filtre XDP](../assets/xdp_lsa5_drop.png)

Par exemple, si `8.8.8.8/32` était accidentellement redistribué sur le
Watcher, le LSA 5 est rejeté par XDP et n'atteint jamais le réseau. La
même protection s'applique aux messages Database Description et aux
réseaux stub supplémentaires dans le LSA 1.

Commandes utiles :

```bash
# Watch XDP drop logs
sudo cat /sys/kernel/debug/tracing/trace_pipe

# Confirm the XDP program is attached to the Watcher's interface
ip l show dev it-vhost1025      # look for "prog/xdp id ..."

# Enable / disable the filter
sudo docker run -it --rm -v ./:/home/watcher/watcher/ --cap-add=NET_ADMIN \
  -u root --network host vadims06/ospf-watcher:latest \
  python3 ./client.py --action enable_xdp --watcher_num <num>
```

## Dépannage

**Mode GRE** — confirmez l'adjacence :

```text
show ip ospf neighbor
```

Votre équipement doit apparaître comme voisin. Sinon, exécutez le script
de diagnostic du Watcher (voir la section dépannage du dépôt).

**Mode BGP-LS** — le Watcher ne publie vers Topolograph qu'une fois la
session BGP établie. Vérifiez-la :

```bash
docker logs watcher<num>-bgpls-ospf-bgplswatcher
docker exec -it watcher<num>-bgpls-ospf-bgplswatcher gobgp neighbor
docker exec -it watcher<num>-bgpls-ospf-bgplswatcher gobgp global rib -a ls
```

Voir [Session BGP-LS](../ingestion/bgp-ls.md#3-verify-the-bgp-ls-session)
pour le déroulé complet de la vérification.

---

**Voir aussi :** [IS-IS Watcher](isis-watcher.md) ·
[ELK / Kibana](elk-kibana.md) · [Zabbix](zabbix.md) · [Webhooks](webhooks.md)

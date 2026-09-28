# SDK Python

Le **SDK Python Topolograph** est un client Python orienté objet pour l'API
REST — accompagné d'un **collecteur SSH** intégré qui récupère les LSDB de vos
équipements, et d'une **CLI** `topo` construite par-dessus.

[:simple-pypi: topolograph-sdk sur PyPI](https://pypi.org/project/topolograph-sdk/){ .md-button }
[:simple-github: vadims06/topolograph-sdk](https://github.com/Vadims06/topolograph-sdk){ .md-button }

## Installation

```bash
pip install topolograph-sdk
```

## Connexion

```python
from topolograph import Topolograph

topo = Topolograph(
    url="http://localhost:8080",
    token="your-api-token",   # or set TOPOLOGRAPH_TOKEN
)

graph = topo.graphs.get(latest=True)
print(graph.graph_time, graph.protocols, graph.hosts['count'])
print(graph.status()['status'])
```

!!! info "Authentification (par ordre de priorité)"
    1. Paramètre **Token** — `Topolograph(url=..., token=...)`
    2. **Environnement** — `export TOPOLOGRAPH_TOKEN=...`
    3. **Authentification de base** — `Topolograph(url=..., username=..., password=...)`

## Collecter la topologie via SSH

Le SDK peut se connecter à vos équipements, exécuter les commandes LSDB
appropriées selon le fournisseur, et vous fournir la sortie brute — prête à
être importée. Les commandes exactes par fournisseur sont listées sur la page
[Fournisseurs pris en charge](../reference/supported-vendors.md).

```python
from topolograph import TopologyCollector

collector = TopologyCollector("inventory.yaml")
result = collector.collect()

graph = topo.uploader.upload_raw(
    lsdb_text=result.raw_lsdb_text,
    vendor="FRR",
    protocol="isis",
)
```

### Format de l'inventaire

```yaml
router1:
  hostname: 172.20.20.2
  username: admin
  password: admin
  vendor: frr
  protocol: isis
  port: 22

router2:
  hostname: 172.20.20.3
  username: admin
  password: admin
  vendor: cisco
  protocol: ospf
```

Requis pour chaque hôte : `hostname`, `username`, `password`, `vendor`
(`cisco`, `juniper`, `frr`, `arista`, `nokia`, `huawei`), et `protocol`
(`ospf` / `isis`). `port` est optionnel (22 par défaut). Un fichier de
démarrage, `inventory.yaml.example`, est fourni avec le projet.

## Travailler avec les graphes

```python
graphs = topo.graphs.list(protocol="ospf")
graph = topo.graphs.get_by_time("2024-01-15T10:30:00Z")

for node in graph.nodes.get():
    print(node.name, node.id)

graph.networks.find_by_ip("10.10.10.1")
graph.networks.find_by_node("1.1.1.1")
graph.networks.find_by_network("10.10.10.0/24")
```

## Calculer des chemins

```python
# Shortest path between nodes
path = graph.paths.shortest("1.1.1.1", "2.2.2.2")
print(path.cost)
for hops in path.paths:
    print(" -> ".join(hops))

# Between IPs/networks
graph.paths.shortest_network("192.168.1.1", "192.168.2.1")

# Backup path (remove an edge and recompute)
graph.paths.shortest("1.1.1.1", "2.2.2.2",
                     removed_edges=[("1.1.1.1", "3.3.3.3")])
```

## Lire les événements

```python
net = graph.events.get_network_events(last_minutes=60)
for e in net['network_up_down_events']:
    print(e.event_object, e.event_status)

adj = graph.events.get_adjacency_events(
    start_time="2024-01-15T10:00:00Z",
    end_time="2024-01-15T11:00:00Z",
)
```

## Filtrer les liens par attributs TE

```python
graph.edges_list(temetric__gte=100)
graph.edges_list(unreserved_bw_0__lt=1e9)
graph.edges_list(src_node="1.1.1.1", dst_node="2.2.2.2", max_link_bw__gt=1e10)
```

Voir [Ingénierie de trafic](../analysis/traffic-engineering.md) pour la liste
des attributs et des opérateurs.

## Tunnels MPLS TE

Lisez le résultat du placement CSPF des tunnels déclarés sur un graphe :

```python
graph.lsps_list()                                    # every tunnel path
graph.lsps_list(status="unplaced")                   # only what failed to place
graph.lsps_list(via_node="10.10.10.2")               # paths crossing a node
graph.lsps_list(via_edge="10.10.10.1,10.10.10.2")    # paths crossing a link
graph.lsps_list(include_path=True)                   # add the expanded node path

graph.lsp("TUN_R1_R3")                               # one tunnel, path always included
```

Chaque chemin porte `placed`, `cost`, et — en cas d'échec — `reason`,
`reason_code` et `binding_constraints`. `reason_code` distingue les deux
types d'échec, qui nécessitent des corrections opposées : `disconnected`
signifie qu'aucun chemin n'existe même en levant toutes les contraintes (il
faut réparer la topologie), tandis que `constraints_unsatisfiable` signifie
qu'un chemin existe mais que la demande est trop stricte — relâchez les
contraintes indiquées dans `binding_constraints` (`bandwidth`, `affinity`,
`srlg`). Plusieurs entrées signifient qu'elles ne bloquent qu'en combinaison.

Utilisez `via_edge_key` au lieu de `via_edge` pour cibler un lien
parallèle/ECMP précis ; obtenez la clé via
`graph.edges_list(include=["edge_key"])`.

Gestion des tunnels :

```python
graph.add_lsp({"name": "TUN_R1_R3", "src": "10.10.10.1", "dst": "10.10.10.3",
               "bandwidth": "2G"})
graph.update_lsp("TUN_R1_R3", bandwidth="5G")
graph.delete_lsp("TUN_R1_R3")
graph.delete_lsps()                                  # all tunnels on the graph
```

Vérifiez si un chemin satisfaisant les contraintes existe, sans créer de
tunnel — la vérification prend en compte la bande passante déjà occupée par
les tunnels placés :

```python
graph.cspf_path("10.10.10.1", "10.10.10.7",
                bandwidth="5G",
                metric_type="te",
                admin_exclude_any=["red"],
                srlg_exclude=[1001],
                setup_priority=0)
# {'path': [...], 'cost': 42, 'reason': ''}
```

Un chemin le plus court classique ignore les tunnels, tout comme le
forwarding IP réel sans autoroute. Passez `with_lsps=True` pour router via
les tunnels `autoroute` :

```python
graph.paths.shortest("10.10.10.1", "10.10.10.4", with_lsps=True)
```

La bande passante TE restante sur un lien une fois tous les tunnels placés
pris en compte :

```python
graph.edges_list(include=["lsp_left_bw"])
```

Voir [Tunnels MPLS TE](../analysis/mpls-te-tunnels.md) pour la référence des
clés YAML et les règles de placement CSPF.

## La CLI `topo`

Le SDK installe une commande `topo` :

```bash
# Graphs
topo graphs --list
topo graphs --latest
topo graphs --list --protocol ospf --watcher production-watcher

# Collect & upload
topo ingest inventory.yaml --protocol isis
topo ingest inventory.yaml --output lsdb.txt
topo ingest inventory.yaml --upload --url http://localhost:8080

# Paths
topo path --src 1.1.1.1 --dst 2.2.2.2
topo path --src 192.168.1.1 --dst 192.168.2.1 --network
topo path --src 1.1.1.1 --dst 2.2.2.2 --graph-time "2024-01-15T10:30:00Z"

# Upload an existing LSDB file
topo upload --file lsdb.txt --vendor FRR --protocol isis
topo upload --file lsdb.txt --vendor Cisco --protocol ospf --watcher prod-watcher
```

## Gestion des erreurs

```python
from topolograph.exceptions import (
    AuthenticationError, NotFoundError, ValidationError, APIError,
)

try:
    graph = topo.graphs.get_by_time("invalid-time")
except NotFoundError:
    ...
except AuthenticationError:
    ...
except APIError as e:
    print(f"API error: {e}")
```

---

**Voir aussi :** [Importer la topologie](../ingestion/index.md) ·
[Serveur MCP](mcp-server.md)

# Python SDK

El **SDK de Python de Topolograph** es un cliente Pythonic y orientado a
objetos para la API REST — además de un **recolector SSH** integrado que
reúne las LSDB de sus dispositivos, y una **CLI** `topo` construida sobre él.

[:simple-pypi: topolograph-sdk on PyPI](https://pypi.org/project/topolograph-sdk/){ .md-button }
[:simple-github: vadims06/topolograph-sdk](https://github.com/Vadims06/topolograph-sdk){ .md-button }

## Instalación

```bash
pip install topolograph-sdk
```

## Conexión

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

!!! info "Autenticación (en orden de prioridad)"
    1. Parámetro **Token** — `Topolograph(url=..., token=...)`
    2. **Entorno** — `export TOPOLOGRAPH_TOKEN=...`
    3. **Autenticación básica** — `Topolograph(url=..., username=..., password=...)`

## Recopilar topología mediante SSH

El SDK puede iniciar sesión en sus dispositivos, ejecutar los comandos LSDB
correctos según el fabricante, y entregarle la salida en bruto — lista
para subir. Los comandos exactos por fabricante se enumeran en la página
[Proveedores compatibles](../reference/supported-vendors.md).

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

### Formato de inventario

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

Obligatorio por host: `hostname`, `username`, `password`, `vendor`
(`cisco`, `juniper`, `frr`, `arista`, `nokia`, `huawei`), y `protocol`
(`ospf` / `isis`). `port` es opcional (por defecto 22). El proyecto incluye
un archivo de ejemplo, `inventory.yaml.example`.

## Trabajar con grafos

```python
graphs = topo.graphs.list(protocol="ospf")
graph = topo.graphs.get_by_time("2024-01-15T10:30:00Z")

for node in graph.nodes.get():
    print(node.name, node.id)

graph.networks.find_by_ip("10.10.10.1")
graph.networks.find_by_node("1.1.1.1")
graph.networks.find_by_network("10.10.10.0/24")
```

## Calcular rutas

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

## Leer eventos

```python
net = graph.events.get_network_events(last_minutes=60)
for e in net['network_up_down_events']:
    print(e.event_object, e.event_status)

adj = graph.events.get_adjacency_events(
    start_time="2024-01-15T10:00:00Z",
    end_time="2024-01-15T11:00:00Z",
)
```

## Filtrar enlaces por atributos de TE

```python
graph.edges_list(temetric__gte=100)
graph.edges_list(unreserved_bw_0__lt=1e9)
graph.edges_list(src_node="1.1.1.1", dst_node="2.2.2.2", max_link_bw__gt=1e10)
```

Consulte [Traffic Engineering](../analysis/traffic-engineering.md) para ver la
lista de atributos y operadores.

## Túneles MPLS TE

Lea el resultado de la colocación CSPF de los túneles declarados en un grafo:

```python
graph.lsps_list()                                    # every tunnel path
graph.lsps_list(status="unplaced")                   # only what failed to place
graph.lsps_list(via_node="10.10.10.2")               # paths crossing a node
graph.lsps_list(via_edge="10.10.10.1,10.10.10.2")    # paths crossing a link
graph.lsps_list(include_path=True)                   # add the expanded node path

graph.lsp("TUN_R1_R3")                               # one tunnel, path always included
```

Cada ruta incluye `placed`, `cost` y — cuando falla — `reason`,
`reason_code` y `binding_constraints`. `reason_code` distingue los dos tipos
de fallo que requieren soluciones opuestas: `disconnected` significa que no
existe ninguna ruta aunque se eliminen todas las restricciones (hay que
reparar la topología), mientras que `constraints_unsatisfiable` significa que
existe una ruta pero la solicitud es demasiado estricta — relaje las
restricciones indicadas en `binding_constraints` (`bandwidth`, `affinity`,
`srlg`). Varias entradas juntas significan que solo bloquean en combinación.

Use `via_edge_key` en lugar de `via_edge` para fijar un enlace paralelo/ECMP
exacto; obtenga la clave con `graph.edges_list(include=["edge_key"])`.

Gestión de túneles:

```python
graph.add_lsp({"name": "TUN_R1_R3", "src": "10.10.10.1", "dst": "10.10.10.3",
               "bandwidth": "2G"})
graph.update_lsp("TUN_R1_R3", bandwidth="5G")
graph.delete_lsp("TUN_R1_R3")
graph.delete_lsps()                                  # all tunnels on the graph
```

Compruebe si existe una ruta que satisfaga las restricciones, sin crear un
túnel — la comprobación tiene en cuenta el ancho de banda ya reservado por
los túneles colocados:

```python
graph.cspf_path("10.10.10.1", "10.10.10.7",
                bandwidth="5G",
                metric_type="te",
                admin_exclude_any=["red"],
                srlg_exclude=[1001],
                setup_priority=0)
# {'path': [...], 'cost': 42, 'reason': ''}
```

Una ruta más corta simple ignora los túneles, tal como lo hace el reenvío IP
real sin autoroute. Pase `with_lsps=True` para enrutar sobre túneles
`autoroute`:

```python
graph.paths.shortest("10.10.10.1", "10.10.10.4", with_lsps=True)
```

Cuánto ancho de banda de TE le queda a un enlace una vez contabilizados
todos los túneles colocados:

```python
graph.edges_list(include=["lsp_left_bw"])
```

Consulte [MPLS TE Tunnels](../analysis/mpls-te-tunnels.md) para ver la
referencia de claves YAML y las reglas de colocación CSPF.

## La CLI `topo`

El SDK instala un comando `topo`:

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

## Manejo de errores

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

**Relacionado:** [Cómo obtener la topología](../ingestion/index.md) ·
[MCP Server](mcp-server.md)

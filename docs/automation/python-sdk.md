# Python SDK

The **Topolograph Python SDK** is a Pythonic, object-oriented client for the
REST API — plus a built-in **SSH collector** that gathers LSDBs from your devices,
and a `topo` **CLI** built on top of it.

[:simple-pypi: topolograph-sdk on PyPI](https://pypi.org/project/topolograph-sdk/){ .md-button }
[:simple-github: vadims06/topolograph-sdk](https://github.com/Vadims06/topolograph-sdk){ .md-button }

## Install

```bash
pip install topolograph-sdk
```

## Connect

```python
from topolograph import Topolograph

topo = Topolograph(
    url="http://localhost:8080",
    token="your-api-token",   # or set TOPOLOGRAPH_TOKEN
)

graph = topo.graphs.get(latest=True)
print(graph.graph_time, graph.protocol, graph.hosts['count'])
print(graph.status()['status'])
```

!!! info "Authentication (in priority order)"
    1. **Token** parameter — `Topolograph(url=..., token=...)`
    2. **Environment** — `export TOPOLOGRAPH_TOKEN=...`
    3. **Basic auth** — `Topolograph(url=..., username=..., password=...)`

## Collect topology over SSH

The SDK can log in to your devices, run the right per-vendor LSDB commands, and
hand you the raw text — ready to upload.

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

### Inventory format

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

Required per host: `hostname`, `username`, `password`, `vendor`
(`cisco`, `juniper`, `frr`, `arista`, `nokia`, `huawei`), and `protocol`
(`ospf` / `isis`). `port` is optional (defaults to 22). A starter file,
`inventory.yaml.example`, ships with the project.

## Work with graphs

```python
graphs = topo.graphs.list(protocol="ospf")
graph = topo.graphs.get_by_time("2024-01-15T10:30:00Z")

for node in graph.nodes.get():
    print(node.name, node.id)

graph.networks.find_by_ip("10.10.10.1")
graph.networks.find_by_node("1.1.1.1")
graph.networks.find_by_network("10.10.10.0/24")
```

## Compute paths

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

## Read events

```python
net = graph.events.get_network_events(last_minutes=60)
for e in net['network_up_down_events']:
    print(e.event_object, e.event_status)

adj = graph.events.get_adjacency_events(
    start_time="2024-01-15T10:00:00Z",
    end_time="2024-01-15T11:00:00Z",
)
```

## Filter links by TE attributes

```python
graph.edges_list(temetric__gte=100)
graph.edges_list(unreserved_bw_0__lt=1e9)
graph.edges_list(src_node="1.1.1.1", dst_node="2.2.2.2", max_link_bw__gt=1e10)
```

See [Traffic Engineering](../analysis/traffic-engineering.md) for the attribute
list and operators.

## The `topo` CLI

The SDK installs a `topo` command:

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

## Error handling

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

**Related:** [Getting topology in](../ingestion/index.md) ·
[MCP Server](mcp-server.md)

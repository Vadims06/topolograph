# YAML-based Topologies

Topolograph usually builds a graph from an OSPF/IS-IS LSDB — but since **v2.32**
it can also build one from a **YAML definition**. That means you can design an
arbitrary topology from scratch (it doesn't even have to be an IGP domain), keep
it updated over the REST API, and run all the same analysis on it.

!!! abstract "Network Diagram as a Service (NDAS)"
    LSDB ⇄ YAML is interchangeable **both ways**. You can design an IGP domain
    from scratch *or* export an uploaded LSDB to YAML, then add links, change
    costs, and re-check the network's reaction to your edits.

## A basic diagram

A YAML diagram is just `nodes` and `edges`:

```yaml
nodes:
  10.10.10.1:
    label: Router1
  10.10.10.2:
    label: Router2
edges:
  - src: 10.10.10.1
    dst: 10.10.10.2
    cost: 10
```

Upload it via the REST API:

```python
import requests

yaml_diagram = """
nodes:
  10.10.10.1:
    label: Router1
  10.10.10.2:
    label: Router2
edges:
  - src: 10.10.10.1
    dst: 10.10.10.2
    cost: 10
"""

requests.post(
    'http://<topolograph-host>/api/diagram',
    auth=('', ''),
    json={'yaml_diagram_str': yaml_diagram},
)
```

…or with the [Python SDK](../automation/python-sdk.md):

```python
from topolograph import Topolograph

topo = Topolograph(url="topolograph-url", token="your-token")
graph = topo.graphs.upload_diagram(yaml_diagram)
print(f"Diagram uploaded: {graph.graph_time}")
```

## Node attributes & tags

- A **node name is mandatory** and must be in IP-address format. To display
  something friendlier, set a `label`.
- **Tags are optional.** Attach any `key: value` pairs (values can be strings,
  numbers, dicts, or lists) — for example `location`, `ha_role`, or anything
  meaningful to you.

Tags make nodes **queryable**. Given a 6-node graph, you can select, say, all
primary nodes in DC1:

```python
query_params = {'location': 'dc1', 'ha_role': 'primary'}
r = requests.get(
    f'http://{HOST}:{PORT}/api/diagram/{graph_time}/nodes',
    auth=('', ''),
    params=query_params,
)
# -> [{'ha_role': 'primary', 'id': 1, 'label': '10.10.10.2',
#      'location': 'dc1', 'name': '10.10.10.2', 'size': 15}]
```

## Edge attributes

Each edge has at minimum a `src`, `dst` and `cost`. Edges can also carry
[Traffic Engineering attributes](traffic-engineering.md) (bandwidth, TE metric,
admin group), which you can then filter on through the diagram edges API.

## Network attributes

Subnets terminated on a node live in a top-level `stub_networks:` section. They
are termination metadata, exactly as when a subnet is parsed from a real LSDB —
no graph node is created for them, so they count towards backup coverage and
network score instead of towards the node count. A subnet advertised by two or
more nodes is treated as backuped.

```yaml
stub_networks:
  192.168.1.0/24:
    - node: 10.10.10.1
      cost: 10
      area: 0
    - node: 10.10.10.2
      cost: 20
      area: 0
```

| key | values / format | meaning |
|---|---|---|
| subnet | CIDR, e.g. `192.168.1.0/24` | the key of each entry; its value is the list of advertising nodes |
| `node` | node name, must exist in `nodes` | node advertising the subnet |
| `cost` | int | cost from that node to the subnet |
| `area` | int | area the subnet is advertised in |
| `metric_type` | int | IS-IS metric style |
| `isnarrow`, `isextended` | bool | IS-IS metric encoding |

Exporting a topology back to YAML keeps this section, so an LSDB → YAML → LSDB
round trip does not lose the subnets.

## MPLS TE tunnels

A diagram can also declare RSVP-TE/SR-TE tunnels in a top-level `lsps:`
section, next to `nodes`/`edges`. Topolograph runs CSPF placement over them
(bandwidth, affinity, SRLG) and lets you query the result, or check whether a
hypothetical new tunnel would fit, without touching the graph.

```yaml
lsps:
  TUN_R1_R3:
    src: 10.10.10.1
    dst: 10.10.10.3
    bandwidth: 2G
```

[:octicons-arrow-right-24: MPLS TE Tunnels](mpls-te-tunnels.md)

## Why use it

- **Design before you build** — model a planned IGP domain and analyze it before
  any device exists.
- **Keep diagrams live** — update nodes/edges over the API as your inventory
  changes (the "as a Service" part of NDAS).
- **Mix in metadata** — tag nodes with site, role, or owner and query the graph
  like a small inventory.

---

**Next:** [Traffic Engineering attributes →](traffic-engineering.md)

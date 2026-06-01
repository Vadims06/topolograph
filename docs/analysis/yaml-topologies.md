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

## Why use it

- **Design before you build** — model a planned IGP domain and analyze it before
  any device exists.
- **Keep diagrams live** — update nodes/edges over the API as your inventory
  changes (the "as a Service" part of NDAS).
- **Mix in metadata** — tag nodes with site, role, or owner and query the graph
  like a small inventory.

---

**Next:** [Traffic Engineering attributes →](traffic-engineering.md)

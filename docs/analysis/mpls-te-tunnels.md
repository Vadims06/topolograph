# MPLS TE Tunnels

On top of [YAML-based topologies](yaml-topologies.md) and
[Traffic Engineering attributes](traffic-engineering.md), a diagram can declare
**MPLS TE tunnels** (RSVP-TE or SR-TE style) in a top-level `lsps:` section.
Topolograph runs CSPF (Constrained Shortest Path First) placement over them —
same bandwidth/affinity/SRLG constraints as a real router, without any
signaling — and visualizes the result.

![MPLS TE tunnels: LSP table and placed paths on the graph](../static/mpls-lsp-graph-and-table.png)

The **LSP tunnels** tab lists every path with its placement status, failure
reason, bandwidth and priorities; selecting a node shows the tunnels that are
ingress, transit or egress on it, and the placed paths are drawn on the canvas.

!!! info "YAML diagrams only, for now"
    `lsps:` is available on YAML-based diagrams. Support for tunnels reported
    live by a watcher is planned for a later release.

## A tunnel in YAML

```yaml
lsps:
  TUN_R1_R3:                    # key = tunnel name
    src: 10.10.10.1
    dst: 10.10.10.3
    metric_type: te             # igp (default) | te
    bandwidth: 2G                # applies to every path unless overridden
    setup_priority: 7
    admin_groups:
      exclude-any: [red]
    color: "#ff9900"
    autoroute: false             # see "autoroute" below
    paths:                       # = LSPs; omit entirely for one dynamic primary
      primary:
        ero:
          - 10.10.10.2                        # plain string = loose hop
          - {node: 10.10.10.3, hop: strict}    # explicit form for a strict hop
      secondary:
        role: standby
        bandwidth: 1G            # overrides the tunnel-level default
        srlg_exclude: [1001]
```

## Key reference

| key | level | values / format | meaning |
|---|---|---|---|
| `lsps` | top-level | dict, tunnel name → body | optional section next to `nodes`/`edges` |
| `src`, `dst` | tunnel | node name (IP-address format) | tunnel endpoints |
| `metric_type` | tunnel | `igp` (default) \| `te` | which metric CSPF optimizes for |
| `bandwidth` | tunnel/path | `2G`, `500M`, or a raw bps number | required bandwidth; a path overrides the tunnel default |
| `setup_priority` | tunnel/path | `0`–`7`, default `7` | RSVP-TE admission pool (`0` is the strongest) |
| `hold_priority` | tunnel/path | `0`–`7`, defaults to `setup_priority` | pool the reservation is held in; may not be weaker than the setup priority |
| `admin_groups` | tunnel/path | dict: `exclude-any` / `include-any` / `include-all` → list of names | affinity filter |
| `srlg_exclude` | path | list of int | SRLG constraint |
| `color` | tunnel | CSS color | highlight color on canvas |
| `autoroute` | tunnel | bool, default `false` | see below |
| `paths` | tunnel | dict, path name → body; omitted = one dynamic `primary` | the tunnel's LSPs |
| `role` | path | `primary` (default) \| `secondary` \| `standby` | path role |
| `ero` | path | list: `10.10.10.2` (loose hop) or `{node: ..., hop: strict}` | explicit route |

A path inherits `bandwidth`, `setup_priority`, `hold_priority` and
`admin_groups` from the tunnel when it omits them. `srlg_exclude` and `ero` are
**not** inherited — declaring `srlg_exclude` at tunnel level has no effect, set
it on each path that needs it.

Edges declare the same TE attributes covered on the
[Traffic Engineering page](traffic-engineering.md#what-topolograph-parses)
(`temetric`, `max_rsrv_link_bw`, `admin_group`/affinity, `srlg`, `unreserved_bw_0`…`unreserved_bw_7`)
— no separate naming for MPLS purposes.

### `autoroute`

A **signaled LSP does not redirect traffic on its own** — that matches real
RSVP-TE/SR-TE behavior: without `autoroute announce` (or an explicit static
route pointing at the tunnel), a tunnel is just reserved bandwidth, invisible
to IGP-style path computation. Set `autoroute: true` on a tunnel to have it
act as a forwarding shortcut in end-to-end path queries (see `with_lsps`
below) — the real-world equivalent of turning on autoroute on the headend.

### Setup and holding priority

`0` is the strongest priority and `7` the weakest. Leave `hold_priority` out
and it follows `setup_priority`, the same as a router's `priority <setup>`
with the second value omitted.

A tunnel set up at a strong priority but held at a weak one would be
preemptable the moment it is signaled, so that combination is rejected:
`hold_priority` must be at least as strong as `setup_priority`
(`setup_priority: 0` with `hold_priority: 7` is a validation error,
`setup_priority: 7` with `hold_priority: 0` is fine).

### Rejected (operational) keys

`rro`, `oper_status`, `active_lsp_name`, and any `label_*` key are **rejected**
in `lsps:` — they describe live signaling state (Record Route, current
status, active path), not declared intent, and only make sense once a real
watcher reports them. A validation error is raised if you include one.

## CSPF placement

On every save, Topolograph places each path in `setup_priority` order (RSVP-TE
convention: `0` highest), same rules a real router would apply:

- filters out edges that don't have enough bandwidth at the requested
  `setup_priority` pool, don't satisfy the affinity filter, or are in an
  excluded SRLG;
- runs the shortest path over what's left, honoring any `ero` (a `strict` hop
  must be a direct edge from the previous hop — the LSP fails rather than
  being silently routed around it);
- subtracts the placed bandwidth from that pool (and every lower-priority
  pool) before placing the next path.

Placement never mutates the advertised TE attributes (`unreserved_bw_*`) — the
consumed capacity is tracked separately, so re-running placement always starts
from the real advertised numbers.

ECMP ties are broken deterministically: fewest hops, then lexicographic order
of node names.

## Reading placement results

`GET /api/graph/{graph_time}/lsps` and `GET /api/graph/{graph_time}/lsps/{name}`
return each path's placement outcome alongside its declared config:

```json
{
  "name": "TUN_R1_R3",
  "src": "10.10.10.1",
  "dst": "10.10.10.3",
  "paths": {
    "primary": {
      "placed": true,
      "reason": null,
      "cost": 20,
      "path": ["10.10.10.1", "10.10.10.2", "10.10.10.3"]
    },
    "secondary": {
      "placed": false,
      "reason": "insufficient bandwidth",
      "cost": null,
      "path": []
    }
  }
}
```

`reason` explains *why* an unplaced path failed, in words. Alongside it,
`reason_code` gives the machine-readable category and `binding_constraints`
names what is actually blocking:

| `reason_code` | meaning | what to do |
|---|---|---|
| `disconnected` | no path exists even with every constraint lifted | repair the topology |
| `constraints_unsatisfiable` | a path exists, the request is too strict | relax the constraints in `binding_constraints` (`bandwidth`, `affinity`, `srlg`) |
| `ero_strict_hop_unreachable` | a strict hop has no edge from the previous hop | fix the `ero` |
| `endpoint_not_found` | `src`/`dst` is not in the graph | fix the endpoint |

Several entries in `binding_constraints` mean they block only in combination —
lifting any one of them is enough.

Useful filters on the list endpoint:

```python
# Which tunnels failed to place, and why
graph.lsps_list(status="unplaced")

# Which tunnels cross a given node or link (pre-maintenance impact check)
graph.lsps_list(via_node="10.10.10.2")
graph.lsps_list(via_edge="10.10.10.1,10.10.10.2")
```

How much TE bandwidth is left on a link, after accounting for every placed
tunnel:

```python
graph.edges_list(include=["lsp_left_bw"])
# -> ..., "lsp_left_bw_7": ..., "lsp_reserved_bw": "7Gbps",
#    "lsp_left_bw": "3Gbps", "lsp_bandwidth_usage": "7Gbps/3Gbps"
```

## CSPF path, without declaring a tunnel

`cspf_path` answers "which path satisfies these constraints, and at what cost"
— a constraint-filtered shortest-path computation, the same class of query as a
plain shortest path. Nothing is created or persisted:

```python
result = graph.cspf_path(
    "10.10.10.1", "10.10.10.7",
    bandwidth="5G",
    admin_exclude_any=["red"],
)
# {'path': [...], 'cost': 42, 'reason': ''}
# or, if nothing fits: {'path': [], 'cost': None, 'reason': 'no path ... satisfies the requested constraints: ...'}
```

The answer accounts for bandwidth the **already declared tunnels hold**: on a
topology with an `lsps:` section the check runs against what each link has
left after placement, not against the advertised value, so the result never
promises capacity that is already taken. Constraints are evaluated per setup
priority, so a link can be full at one priority and still have room at a
stronger one.

Affinity constraints (`admin_exclude_any`, `admin_include_any`,
`admin_include_all`) match affinity **names** on the link. Topologies ingested
from a live network advertise the admin group as a bitmask, so a name-based
`include-any`/`include-all` on those graphs matches nothing and the answer is
"no path" — use `exclude-any` or a YAML topology with named affinities there.

## End-to-end path via tunnels (`with_lsps`)

By default, `graph.paths.shortest(src, dst)` is a plain IGP path — unaffected
by any tunnel in the graph, same as real IP forwarding without autoroute.
Pass `with_lsps=True` to account for `autoroute: true` tunnels as forwarding
shortcuts:

```python
graph.paths.shortest("10.10.10.1", "10.10.10.4")               # plain IGP path
graph.paths.shortest("10.10.10.1", "10.10.10.4", with_lsps=True) # via active autoroute tunnels
```

## What breaks if a link goes down?

`edge_failure_reaction` predicts the whole-network impact of one or more
links failing — connectivity, and which links pick up or lose traffic:

```python
graph.paths.edge_failure_reaction([("10.10.10.1", "10.10.10.2")])
# {'isGraphStillConnected': True, 'affectedLinks': {...}, 'disjointedNodes': []}
```

For a per-tunnel view of the same question, combine it with `lsps_list(via_edge=...)`
to see which tunnels traverse the link before checking its failure impact.

---

**Related:** [YAML-based Topologies](yaml-topologies.md) ·
[Traffic Engineering attributes](traffic-engineering.md) ·
[Python SDK](../automation/python-sdk.md)

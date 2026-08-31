# BMP Watcher

**BMP Watcher** brings the BGP control plane into Topolograph: peering
sessions, the routes carried over them, VPN context, and every change to both.

It is a passive [BMP](https://datatracker.ietf.org/doc/html/rfc7854) station.
Routers open a TCP session towards it and stream their Adj-RIB-In. The watcher
never speaks BGP, never peers, and never connects to a router itself — so it
adds no BGP state to the network it observes.

!!! info "BGP state is kept separate from your IGP graph"
    A BGP session is a control-plane relationship, not a forwarding link. BGP
    is stored as its own graph with its own lifecycle and is *bound* to your
    OSPF and IS-IS graphs, never merged into them. A BGP graph also works on
    its own, with no IGP graph present at all.

---

## What it collects

### Address families

| Family | AFI | SAFI | Reported as |
|---|---:|---:|---|
| IPv4 unicast | 1 | 1 | `prefix` |
| IPv6 unicast | 2 | 1 | `prefix` |
| VPNv4 | 1 | 128 | `l3vpn` |
| VPNv6 | 2 | 128 | `l3vpn` |
| EVPN | 25 | 70 | `evpn` |

A VPN route is unique only together with its Route Distinguisher, so the RD is
part of its identity. An EVPN route has no prefix at all and is identified by
its RFC 7432 NLRI components — route type, Ethernet Segment ID, Ethernet Tag,
MAC, IP.

### BMP messages

| BMP message | What Topolograph does with it |
|---|---|
| Route Monitoring | builds the table, and every subsequent route change |
| Peer Up | session state, plus the peer's BGP Identifier — the Router ID events are attributed to |
| Peer Down | session teardown, plus a withdraw per route that peer carried |
| Initiation / Termination | collector session lifecycle |
| Statistics Report | ignored — counters are not routing state |

### Policy streams and evidence

Both Adj-RIB-In streams are stored separately, and where the speaker supports
[RFC 9069](https://datatracker.ietf.org/doc/html/rfc9069) the Loc-RIB stream is
kept as a third observation:

| Stream | Evidence level | Means |
|---|---|---|
| `pre` / `out-pre` | `pre_policy` | the peer advertised it; the router may have rejected it |
| `post` / `out-post` | `post_policy` | the router accepted it — a candidate path |
| `loc-rib` | `loc_rib` | the router's own selection — the installed best path |
| `fib` | `fib` | present in the forwarding table |

These are never merged. A route seen only pre-policy is **never** reported as
selected or installed — that distinction is the reason both streams exist.

### Observations, not subnets

The same prefix is stored once per speaker, once per peer, once per path ID and
once per policy stream. Every copy survives, because "who advertised what to
whom" is exactly the question a monitored table answers.

---

## Try it first without a real network

Topolograph generates a BGP demo topology and opens it automatically on your
first visit — 13 routers, 22 BGP sessions, two route reflectors with
deliberately different BMP capabilities. The BGP overlay is on by default.

To explore it you do **not** need to configure BMP export on any router, run
bmpwatcher, or run the Fluent Bit shipper — those deliver data from a real
network. The step-by-step walkthrough, with screenshots, is the in-app guide at
[`/how-to/bgp`](https://topolograph.com/how-to/bgp).

---

## Installing the collector

The collector is [**bmpwatcher**](https://github.com/Vadims06/bmpwatcher) — a
Go BMP station that separates the initial table replay from the changes that
follow it. Its README covers building, running under Docker, and the router-side
BMP configuration for FRR, IOS-XR, Junos and SR OS.

Minimal run, writing both a snapshot and an event stream:

```bash
bmpwatcher \
  --bmp-port=11019 \
  --source-id=pe1 \
  --watcher-name=bmp-dc1 \
  --events=/var/log/bmpwatcher/events.jsonl \
  --topolograph-topology-url=https://topolograph.com/api/watcher/bgp
```

!!! warning "Authentication is not wired into the collector yet"
    `/api/watcher/bgp` requires `Authorization: Bearer sk-...`, and the
    collector does not attach that header yet — a direct post is answered with
    `401`. Until it ships, write the document locally with
    `--topolograph-topology-file` and post it yourself (see the `curl` example
    below).

Get the token from **Settings → API Tokens → Create token**. The workspace is
resolved from the token on the server and is never taken from the payload.

---

## Ingest API

### `POST /api/watcher/bgp` — the topology snapshot

The collector assembles the whole table over its collection window and posts it
as one document.

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

| Field | Meaning |
|---|---|
| `time` | snapshot timestamp, ISO 8601 — also the staleness key |
| `srcid` | the collector instance |
| `sesid` | one collector *run*; changes on every restart |
| `nodes[].role` | `speaker` reports; `peer` was only reported about |
| `edges[]` | one BGP **session**, not one router pair |
| `networks[]` | one route **observation** |
| `networks[].type` / `subtype` | AFI as a string, SAFI as a number |
| `networks[].data` | the untouched collector record, so unpromoted attributes are never lost |

**Response**

```json
{"graph_time": "17Aug2026_09h12m03s_6_hosts", "checkpoint": false, "routes": 1428}
```

`graph_time` is the public identifier used by every read endpoint below — the
same format IGP graphs use.

**Ordering and re-sends.** `sesid` is minted at collector start-up, exactly when
speakers replay their tables. Within one `sesid` the newest `time` wins; an
older or equal one is rejected with `400 stale snapshot`. A periodic full
re-send under the same `sesid` is treated as a **reconciliation checkpoint**,
not a new graph — it returns `checkpoint: true`, proves the source is alive on a
quiet network, and corrects the current view if it has drifted. A new `sesid`
supersedes the previous run.

All Route Targets are extracted from `data.base_attrs.ext_community_list`, not
only the promoted `rt` field — a route with several RTs stays visible to a query
for any of them.

### `POST /api/watcher/bgp/events` — the change stream

Accepts one event object or a list of them.

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

| Field | Meaning |
|---|---|
| `event_name` | `prefix`, `l3vpn`, `evpn`, `peer` |
| `event_status` | `add`, `change`, `withdraw` (routes); `up`, `down` (peers) |
| `event_detected_by` | the router the change is about |
| `bmp_source` | the speaker that reported it — a different router on any reflected session |
| `seq` | monotonic per `sesid`; used for exact dedup and gap detection |
| `watcher_time` | collector clock — orders the stream |
| `bmp_timestamp` | router clock — correlation only, never ordering |
| `replay_suspect` | may be the tail of a replay rather than a live change |

```json
{"accepted": 1, "duplicates": 0}
```

An event whose `(srcid, sesid)` does not match a stored snapshot is rejected —
**post the topology before starting the event feed**. A repeated `seq` is
counted as a duplicate and dropped; a gap in `seq` is logged as a lost message.

A peer up/down event is display-only. The collector already emits an ordinary
per-prefix withdraw for every route a downed peer carried, so the peer event
itself never mutates route state.

### `POST /api/watcher/vrfs` — VRF inventory

Route Distinguishers identify VPN routes, but only the device knows the VRF
*name* and its import/export Route Targets. Posting the inventory lets you
search by VRF name instead of by RD.

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

Each observation is stored with its own timestamp rather than overwriting the
previous one, so an older graph can still resolve the VRF state as it was at
that time. Uniqueness is `(workspace, router_id, rd)`; an unchanged re-send
writes nothing.

---

## Binding to your IGP graphs

After every BGP **and** every IGP save, Topolograph re-evaluates which OSPF or
IS-IS graphs a BGP graph belongs to. Candidates are ranked by Router-ID overlap
using a greedy set-cover, so a BGP graph spanning two IGP domains binds to both.

| State | Meaning |
|---|---|
| `bound` | Router-ID overlap ≥ 80 %, unambiguous |
| `needs_mapping` | below the floor, or two candidates tie — waiting for confirmation |

Router-ID overlap is **evidence, not a requirement**. A BGP Router ID and an
OSPF Router ID usually match, but Topolograph never insists on it: ambiguous
results stay visible for you to confirm.

```bash
# what a BGP graph is bound to
curl -sS ".../api/bgp-graph/17Aug2026_09h12m03s_6_hosts/bindings" -H "Authorization: Bearer $T"

# confirm a binding by hand
curl -sS -X PUT ".../api/bgp-graph/<bgp_graph_time>/<igp_graph_time>/binding" -H "Authorization: Bearer $T"

# drop one
curl -sS -X DELETE ".../api/bgp-graph/<bgp_graph_time>/<igp_graph_time>/binding" -H "Authorization: Bearer $T"
```

!!! note "IS-IS needs a real Router ID"
    An IS-IS node is named internally by a parser-minted pseudo Router ID that
    exists nowhere on the network. Only a **TE Router ID** advertised by the
    device counts as an identity. A device that advertises none contributes
    nothing to the overlap score — which is the honest outcome, not a bug.
    Enable TE on the device, or set the Router ID by hand on the
    **hostname mapping** page; it then migrates to later graphs the way a
    hostname does.

---

## Reading it back

### Graphs, nodes and sessions

```bash
GET /api/bgp-graphs?page=1&per_page=50
GET /api/bgp-graph/{bgp_graph_time}
GET /api/bgp-graph/{bgp_graph_time}/nodes?role=rr&asn=65001
GET /api/bgp-graph/{bgp_graph_time}/sessions?igp_relation=inter-domain&bgp_session_type=ebgp
```

Each session is classified once the bindings are known:

| `igp_relation` | Meaning |
|---|---|
| `intra-domain` | both ends are in the same bound IGP graph |
| `inter-domain` | the ends are in two different bound IGP graphs |
| `external` | at least one end is in no bound IGP graph |

`bgp_session_type` is `ibgp` or `ebgp`, derived from the session's ASN against
the speaker's own — not from `AS_PATH[0]`, which a reflected route would make
misleading.

### Route search

```bash
GET /api/bgp-graph/{bgp_graph_time}/routes?prefix=192.0.2.0/24
GET /api/bgp-graph/{bgp_graph_time}/node/{router_id}/routes?evidence=loc_rib
```

| Query | Behaviour |
|---|---|
| `prefix=192.0.2.0/24` | exact match on the full prefix |
| `prefix=192.0.2.5` | containment — every route covering the address |
| `prefix=192.0.2.0/24&lpm=1` | longest-prefix match, one row |
| `afi` / `safi` | numeric family |
| `rd` | Route Distinguisher |
| `vrf` | VRF name, resolved to its RDs through the inventory |
| `rt` | any Route Target on the route |
| `policy` / `evidence` | raw stream, or `pre_policy` / `post_policy` / `loc_rib` / `fib` |
| `as_path_contains` | substring match anywhere in AS_PATH |
| `community` / `large_community` / `extended_community` | community search |
| `origin`, `local_pref`, `med`, `originator_id`, `label` | attribute filters |
| `peer_ip`, `nexthop`, `bmp_source` | who advertised it, and how it is reached |
| `page`, `per_page` | pagination (`per_page` capped at 500) |

Every route carries VRF/RD/RT, AFI/SAFI, policy and evidence, path ID,
communities, next hop, labels and origin.

### History and comparison

```bash
# state of the table now, or as it was at a point in time
GET /api/bgp-graph/{bgp_graph_time}/routes/state
GET /api/bgp-graph/{bgp_graph_time}/routes/state?at=2026-08-17T09:20:00Z

# what changed between two moments
GET /api/bgp-graph/{bgp_graph_time}/routes/compare?t0=...&t1=...

# the event feed, and the monitoring-timeline lanes
GET /api/bgp-graph/{bgp_graph_time}/events?last_minutes=60&event_name=peer
GET /api/bgp-graph/{bgp_graph_time}/events/timeline
```

`state` with no `at` reads a continuously maintained current view, so it costs
the size of the answer rather than a replay of the whole event log. An explicit
`at` replays deltas from the snapshot baseline through that moment. Time bounds
are inclusive at both ends.

`compare` returns one row per change: `added`, `withdrawn` or `changed` with
before/after.

On the monitoring timeline, `bgp_peer` gets one marker per session up/down —
low volume, every flap matters — while `bgp_route` is clustered, so a burst of
route churn renders as one marker with a count instead of thousands of dots.

### Route lookup

Route lookup answers "what does this router actually do with this destination",
as opposed to a pure topology SPF.

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

The decision order is deliberate:

1. **Longest-prefix match** inside the selected table or VRF.
2. **BGP best-path selection** — one path per prefix, on LOCAL_PREF, AS_PATH
   length, ORIGIN and MED, before anything else compares protocols. A Loc-RIB
   observation ends the comparison: it is the router's own choice.
3. **Administrative distance** between the surviving candidates of different
   protocols.
4. **Recursive next-hop resolution**, loop- and depth-guarded.
5. **IGP SPF/CSPF transport** toward that next hop, optionally over eligible
   LSP shortcuts.

| Protocol | AD |
|---|---:|
| connected | 0 |
| static | 1 |
| eBGP | 20 |
| OSPF | 110 |
| IS-IS | 115 |
| iBGP | 200 |

Administrative distance belongs to **routes**, never to topology edges.
Metrics from OSPF, IS-IS and BGP are never compared with each other — a metric
is only meaningful inside its own protocol. iBGP versus eBGP is decided by the
session the route was learned on, not by `AS_PATH[0]`.

Candidate routes are scoped to what the starting node can actually see: its own
reported table plus the tables of its direct session neighbours. A router
running no BGP inherits nothing.

---

## Retention

Topolograph keeps the most recent BGP graphs **per source** (`srcid`), so an
installation running two collectors keeps a full window for each. When an epoch
falls out of the window, its routes and bindings go with it. Periodic re-sends
under the same `sesid` are checkpoints and do not consume the window.

---

## Current limits

- The collector does not yet attach the API token; post the snapshot with
  `curl` in the meantime.
- Run one collector per BMP speaker and set `--source-id`. Several speakers
  into one collector merge their observations.
- EVPN routes are collected and stored, but the route table and route lookup
  are prefix-oriented; EVPN is not yet a first-class search subject.
- A Router ID that legitimately appears in two bound IGP domains resolves to
  one of them for session classification.

---

## See also

- [bmpwatcher on GitHub](https://github.com/Vadims06/bmpwatcher)
- [OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)
- [Events, Timeline & Status](events-timeline.md)
- [BGP-LS Session](../ingestion/bgp-ls.md) — BGP-LS carries *IGP* topology, a
  different subject from the BGP routing state on this page

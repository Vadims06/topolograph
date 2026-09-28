# BMP Watcher

**BMP Watcher** brings the BGP control plane into Topolograph: peering
sessions, the routes carried over them, VPN context, and every change to both.

It is a passive [BMP](https://datatracker.ietf.org/doc/html/rfc7854) station.
Routers open a TCP session towards it and stream their Adj-RIB-In. The watcher
never speaks BGP, never peers, and never connects to a router itself - so it
adds no BGP state to the network it observes.

[:simple-github: vadims06/bmpwatcher](https://github.com/Vadims06/bmpwatcher){ .md-button }

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
its RFC 7432 NLRI components - route type, Ethernet Segment ID, Ethernet Tag,
MAC, IP.

### BMP messages

| BMP message | What Topolograph does with it |
|---|---|
| Route Monitoring | builds the table, and every subsequent route change |
| Peer Up | session state, plus the peer's BGP Identifier - the Router ID events are attributed to |
| Peer Down | session teardown, plus a withdraw per route that peer carried |
| Initiation / Termination | collector session lifecycle |
| Statistics Report | ignored - counters are not routing state |

### Policy streams and evidence

Both Adj-RIB-In streams are stored separately, and where the speaker supports
[RFC 9069](https://datatracker.ietf.org/doc/html/rfc9069) the Loc-RIB stream is
kept as a third observation:

| Stream | Evidence level | Means |
|---|---|---|
| `pre` / `out-pre` | `pre_policy` | the peer advertised it; the router may have rejected it |
| `post` / `out-post` | `post_policy` | the router accepted it - a candidate path |
| `loc-rib` | `loc_rib` | the router's own selection - the installed best path |
| `fib` | `fib` | present in the forwarding table |

These are never merged. A route seen only pre-policy is **never** reported as
selected or installed - that distinction is the reason both streams exist.

---

## Installing the collector

!!! note "Compatibility"
    The BGP graph and this collector need
    [topolograph v2.69](https://github.com/Vadims06/topolograph/releases/tag/v2.69)
    or later; EVPN needs v2.73 and BMP Watcher v1.1.0.

To try it without a real network, run the [13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp) containerlab lab from the bmpwatcher repository.

The collector is [**bmpwatcher**](https://github.com/Vadims06/bmpwatcher), published
as the Docker image `vadims06/bmpwatcher:latest`: a passive BMP station that routers connect
to on TCP 11019, it never connects to a router. It separates the initial table replay
from the changes that follow. Its README covers the router-side BMP configuration for
FRR, IOS-XR, Junos and SR OS.

You need a Topolograph account: sign up at topolograph.com, or on a self-hosted
instance log in with the user set in its `.env` (`TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `TOPOLOGRAPH_WEB_API_PASSWORD`).
Create an API token: **API → Token → Create Token**. The workspace is resolved from
the token on the server and is never taken from the payload.

### Run with Docker Compose

The compose file of the bmpwatcher repository runs the collector and the Fluent Bit event shipper together:

```bash
git clone https://github.com/Vadims06/bmpwatcher.git && cd bmpwatcher
cp .env.example .env
docker compose --profile collector up -d
```

Set in `.env`:

- `TOPOLOGRAPH_HOST`: the IP address of the Docker host, not `localhost`, because Topolograph and BMP Watcher run in their own container networks; `topolograph.com` for the public instance.
- `TOPOLOGRAPH_PORT`: `8080` by default, `443` for topolograph.com.
- `WEBHOOK_TLS_ON`: `off` for a self-hosted Topolograph, `on` for topolograph.com.
- `TOPOLOGRAPH_API_TOKEN`: the `sk-...` token.
- `SOURCE_ID`: the name of this collector in Topolograph, e.g. `dc1-rr`. Keep it stable: a container recreated with the same name keeps its data together.
- `BMPWATCHER_LOG_DIR`: where the collector writes its files, `/var/log/bmpwatcher` by default.

Stop it with the same profile: `docker compose --profile collector down`. Enable Docker at boot (`systemctl enable docker`): the containers restart after a crash and a reboot.

The first snapshot goes out once every router has replayed its table: about 30 seconds after its routes stop arriving, at most 5 minutes after the first one. Check that it was sent:

```bash
docker logs bmpwatcher 2>&1 | grep 'topology posted'
```

### EVPN: first messages

*Topolograph v2.73 or later, BMP Watcher v1.1.0 or later. EVPN export is verified on FRR.*

EVPN is answered on your OSPF or IS-IS graph, so Topolograph needs one whose
Router IDs match the BGP speakers.

1. **Get the IGP graph.** For your own network, upload its LSDB or run
   [OSPF Watcher](ospf-watcher.md) / [IS-IS Watcher](isis-watcher.md). For the
   [13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp) lab, its OSPF underlay is the 13-router demo
   graph Topolograph creates in every account on first sign-in; for IS-IS,
   upload [demo_isis_LSDB.txt](https://github.com/Vadims06/topolograph/blob/master/demo_isis_LSDB.txt) as FRR IS-IS.
2. **Enable BMP on the route reflectors**: they hold every leaf's EVPN routes,
   while a leaf exports only what it learned. FRR loads BMP as a module, so add
   `-M bmp` to `bgpd_options` and restart FRR:

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

In containerlab, edit the lab's `daemons` file and redeploy the lab: restarting FRR
inside a running container drops its lab links. `bmp connect` takes an address of
the collector host that the routers reach on TCP 11019; in containerlab that is the
gateway of the lab's management network (`docker network inspect <mgmt-network>`).

3. **Start the collector** as above.
4. **Check the answer on the IGP graph**: the graph whose `protocols` include
   `bgp`, its VNIs and VRFs, and the leaves of one VNI.

```bash
TOPOLOGRAPH_URL=http://<host-ip>:8080   # https://topolograph.com for the public instance
curl -sS "$TOPOLOGRAPH_URL/api/graph/?protocol=bgp" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
curl -sS "$TOPOLOGRAPH_URL/api/graph/<graph_time>/vpns" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
curl -sS "$TOPOLOGRAPH_URL/api/graph/<graph_time>/nodes?protocol=bgp&vni=<vni>" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
```

An empty `?protocol=bgp` list means the BGP graph is not bound yet: check
`GET /api/bgp-graph/<bgp_graph_time>/bindings`. The initial table arrives in
the snapshot; the event feed carries only the changes after it.

Every account holds a demo BGP graph captured on the
13-hosts-demo-bgp lab and bound to the same demo graph, so on that graph the answers
include the demo routes too.

---

## Binding to your IGP graphs

After every BGP **and** every IGP save, Topolograph re-evaluates which OSPF or
IS-IS graphs a BGP graph belongs to. Candidates are ranked by Router-ID overlap
using a greedy set-cover, so a BGP graph spanning two IGP domains binds to both.

| State | Meaning |
|---|---|
| `bound` | Router-ID overlap ≥ 80 %, unambiguous |
| `needs_mapping` | below the floor, or two candidates tie - waiting for confirmation |

A BGP graph binds first to the IGP graph that was in effect at its own time:
the latest one not newer than the BGP graph. IGP snapshots taken later, while
it is still the newest BGP graph of its source, are bound too, as long as they
keep the routers the first match found. A router that joined after the IGP
snapshot is counted from its OSPF adjacency events.

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
    nothing to the overlap score - which is the honest outcome, not a bug.
    Enable TE on the device, or set the Router ID by hand on the
    **hostname mapping** page; it then migrates to later graphs the way a
    hostname does.

---

## Querying BGP data

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
the speaker's own - not from `AS_PATH[0]`, which a reflected route would make
misleading.

### Route search

```bash
GET /api/bgp-graph/{bgp_graph_time}/routes?prefix=192.0.2.0/24
GET /api/bgp-graph/{bgp_graph_time}/node/{router_id}/routes?evidence=loc_rib
```

| Query | Behaviour |
|---|---|
| `prefix=192.0.2.0/24` | exact match on the full prefix |
| `prefix=192.0.2.5` | containment: every route covering the address, longest prefix first |
| `afi` / `safi` | numeric family |
| `mac`, `vni` | EVPN only, see [EVPN](#evpn) |
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

On the monitoring timeline, `bgp_peer` gets one marker per session up/down -
low volume, every flap matters - while `bgp_route` is clustered, so a burst of
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
2. **BGP best-path selection** - one path per prefix (RFC 4271 §9.1;
    RFC 4456 for reflected routes, RFC 4364 for VPNs), over the attributes a
    collector feed carries:

    1. highest `LOCAL_PREF`
    2. shortest `AS_PATH`
    3. lowest `ORIGIN` (IGP < EGP < incomplete)
    4. lowest `MED`, compared only within the same neighbouring AS
    5. eBGP-learned over iBGP-learned
    6. lowest `ORIGINATOR_ID` / BGP Identifier

    A Loc-RIB observation ends the comparison before these steps run - it is the
    router's own choice, not a candidate to re-rank.

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
Metrics from OSPF, IS-IS and BGP are never compared with each other - a metric
is only meaningful inside its own protocol. iBGP versus eBGP is decided by the
session the route was learned on, not by `AS_PATH[0]`.

Candidate routes are scoped to what the starting node can actually see: its own
reported table plus the tables of its direct session neighbours. A router
running no BGP inherits nothing.

---

## EVPN

*Topolograph v2.73 or later, BMP Watcher v1.1.0 or later.*

BGP EVPN over VXLAN (AFI 25 / SAFI 70) is read from the BMP feed of the route
reflectors. Every EVPN question is asked on your OSPF or IS-IS graph: its bound
BGP graph answers it, and each VTEP is resolved to the router that owns the
address, so a path to a host ends at the leaf behind it.

### Route types

| Route type | RFC | Used for |
|---|---|---|
| 1 Ethernet Auto-Discovery | [RFC 7432](https://datatracker.ietf.org/doc/html/rfc7432) | stored and searchable |
| 2 MAC/IP Advertisement | RFC 7432 | where a host is: MAC, IP, VNI, VTEP, ESI; MAC moves |
| 3 Inclusive Multicast Ethernet Tag | RFC 7432, [RFC 6514](https://datatracker.ietf.org/doc/html/rfc6514) | which leaves are VTEPs of a VNI (the VNI comes from the PMSI Tunnel attribute) |
| 4 Ethernet Segment | RFC 7432 | stored and searchable |
| 5 IP Prefix | [RFC 9136](https://datatracker.ietf.org/doc/html/rfc9136) | subnets of a VRF and its L3VNI |

### Route attributes

An EVPN route carries the usual RD, route targets, next hop and communities,
plus an `evpn` object:

| Field | Meaning |
|---|---|
| `route_type` | 1 to 5 |
| `mac` | host MAC (RT-2) |
| `ip`, `ip_len` | host IP (RT-2), prefix and its length (RT-5), originating router (RT-3, RT-4) |
| `vni` | L2VNI (RT-2, RT-3) |
| `l3vni` | L3VNI of the VRF (RT-5, and RT-2 with symmetric IRB) |
| `esi` | Ethernet Segment ID; all zeros means a single-homed host |
| `eth_tag` | Ethernet Tag ID |
| `vtep` | the VTEP: the originating router for RT-3 and RT-4, the next hop for the others |
| `mm_seq` | MAC Mobility sequence number ([RFC 7432 §15](https://datatracker.ietf.org/doc/html/rfc7432#section-15)) |

For RT-2 and RT-5 `prefix` is also set (the host address at /32 or /128, or the
RT-5 prefix), so `prefix=` finds EVPN hosts and subnets like any other route.

```json
{
  "afi": 25, "safi": 70, "rd": "1:123.123.31.31:5",
  "route_targets": ["65000:1020"], "nexthop": "123.123.31.31",
  "evpn": {"route_type": 2, "mac": "00:c1:ab:00:00:03", "ip": null, "ip_len": null,
           "vni": 1020, "l3vni": null, "esi": "00:00:00:00:00:00:00:00:00:00",
           "eth_tag": 0, "vtep": "123.123.31.31", "mm_seq": null}
}
```

### Questions it answers

All of them are asked on the IGP graph (`{graph_time}`), with no BGP graph
time.

| Question | Request |
|---|---|
| Which VNIs and VRFs does the fabric have? | `GET /api/graph/{graph_time}/vpns` |
| Which VPNs does one router see? | `GET /api/graph/{graph_time}/node/{router_id}/vpns` |
| Which leaves carry VNI 1020, or VRF tenant1? | `GET /api/graph/{graph_time}/nodes?protocol=bgp&vni=1020` (or `vrf=tenant1`) |
| Where is a host: leaf, VNI, VRF, MAC? | `GET /api/graph/{graph_time}/routes?prefix=10.10.20.13` or `?mac=00:c1:ab:00:00:03` |
| Is a host multihomed? | the same request: several VTEPs with one non-zero `esi` |
| What does a VRF route? | `GET /api/graph/{graph_time}/routes?vrf=tenant1` |
| What does one leaf hold for a VNI? | `GET /api/graph/{graph_time}/node/{router_id}/routes?vni=1010` |
| Did a MAC move, from which leaf to which, when? | `GET /api/events/{graph_time}/routes?mac=00:c1:ab:00:00:01&last_minutes=60` |
| How does the underlay reach every VTEP of a VNI? | `GET /api/graph/{graph_time}/path/{node_a}/{vtep1},{vtep2}` |

`routes` also takes `at=` for a past moment, and `vtep=`, `rt=`, `rd=`, `page`,
`per_page`. In the event history, the row where a MAC appears on a new VTEP
carries `moved_from_vtep`. The same MAC advertised by several VTEPs under one
ESI is multihoming, not a move.

A VPN row groups routes by VRF name when the VRF inventory knows it, otherwise
by route target; an EVPN bridge domain is one row per L2VNI:

```json
{"name": null, "vni": 1020, "l3vni": 5000,
 "route_targets": ["65000:1020", "65000:5000"],
 "route_distinguishers": ["1:123.123.30.30:5", "1:123.123.31.31:5"],
 "prefix_count": 4}
```

In the UI the same answers are in the BGP / VPN path form and in the Graph
table, BGP Routes, which has columns for every field above. A walkthrough on the
demo data is in the [BGP how-to](https://topolograph.com/how-to/bgp#evpn), and
the lab it was captured on is
[containerlab/13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp).

---

## Current limits

- EVPN assumes VNIs are fabric-global: locally significant VNIs (RFC 8365)
  are not supported.
- Which leaf is the designated forwarder of an Ethernet Segment is decided on
  the leaves and is not carried over BMP.
- A Router ID that legitimately appears in two bound IGP domains resolves to
  one of them for session classification.

---

## See also

- [bmpwatcher on GitHub](https://github.com/Vadims06/bmpwatcher)
- [OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)
- [Events, Timeline & Status](events-timeline.md)
- [BGP-LS Session](../ingestion/bgp-ls.md) - BGP-LS carries *IGP* topology, a
  different subject from the BGP routing state on this page

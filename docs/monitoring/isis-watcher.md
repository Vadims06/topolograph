# IS-IS Watcher

**IS-IS Watcher** is the IS-IS counterpart of the [OSPF Watcher](ospf-watcher.md).
It passively listens to the IS-IS control plane — over a
[GRE adjacency](../ingestion/gre.md) or [BGP-LS](../ingestion/bgp-ls.md) — and logs
or exports every change to **ELK**, **Zabbix**, **WebHooks**, and the
**Topolograph** monitoring dashboard. Like the OSPF Watcher, it ships as
containers.

[:simple-github: vadims06/isiswatcher](https://github.com/Vadims06/isiswatcher){ .md-button }

![IS-IS Watcher + Topolograph architecture](../assets/isiswatcher_architecture.png)

## Detected events

- IS-IS neighbor adjacency **Up/Down**
- IS-IS link **cost changes**
- IS-IS networks **appearing/disappearing**
- IS-IS **TE attributes**: administrative group, maximum link bandwidth, maximum
  reservable bandwidth, unreserved bandwidth, and TE default metric
- IS-IS **node flags**: **overload (OL)** and **attached (ATT)** transitions
  (plus ABR/ASBR derived over BGP-LS)

Everything is grouped by **IS-IS level (L1/L2)** on the timeline:

![Topolograph dashboard with L1/L2 IS-IS events](../assets/dashboard_l1_l2_events.png)

!!! example "What the levels look like"
    A typical capture might show: a metric change on a link appearing as
    **duplicated logs for both L1 and L2**; a router going **down for L2 only**
    after `isis circuit-type level-1` is applied; a later metric change seen
    **only in L1**; and a new stub network appearing **in L2**.

## Connecting it

Connection setup lives under [Getting Topology In](../ingestion/index.md):

- [**GRE mode**](../ingestion/gre.md) — FRR forms an IS-IS adjacency over a GRE
  tunnel; an **XDP IS-IS filter** keeps the Watcher listen-only by dropping any
  LSP that advertises more than the Watcher's own network.
- [**BGP-LS mode**](../ingestion/bgp-ls.md) — the router exports IS-IS topology
  over BGP-LS; GoBGP + the forwarder feed the Watcher.

![GRE FRR individual instances per area](../assets/gre_frr_instances.png)

!!! warning "One GRE tunnel per area"
    IS-IS, like OSPF, floods per area/level. In GRE mode you need **at least one
    GRE tunnel into each area** you want to monitor — this is a property of
    link-state flooding, not a tool limitation. BGP-LS avoids this by carrying the
    whole domain over a single session.

!!! note "Compatibility"
    IS-IS network changes appear on the graph with
    [topolograph v2.38](https://github.com/Vadims06/topolograph/releases/tag/v2.38)
    or later.

## TLV and metric support

IS-IS Watcher parses both old-style (narrow) and new-style (wide) metrics and
supports IPv6 reachability. The TLVs it understands — and the per-vendor support
matrix — are summarized on the
[Supported Vendors](../reference/supported-vendors.md#is-is-tlv-support) page.

Key TLVs: IS Reachability (2), Extended IS Reachability (22), IPv4 Internal/
Extended Reachability (128/135), and IPv6 Reachability (236).

!!! info "Custom FRR build"
    Running IS-IS over GRE requires an FRR build capable of it; the IS-IS Watcher
    repo provides the necessary build. See the
    [repository](https://github.com/Vadims06/isiswatcher) for details.

## Quick lab (containerlab)

The repo ships a containerlab topology for trying IS-IS monitoring end to end —
see the `containerlab/` directory and the
[deployment sizes](index.md#deployment-sizes) table for how to layer on
Topolograph and ELK.

!!! tip "No device? Test mode"
    As with the OSPF Watcher, `TEST_MODE` replays demo IS-IS events from a static
    file so you can exercise the whole pipeline without hardware.

## Event log format

IS-IS Watcher emits the same comma-separated event records as the OSPF Watcher
(with the IS-IS **level** carried alongside) — so the
[ELK](elk-kibana.md), [Zabbix](zabbix.md) and [Webhook](webhooks.md) integrations
work identically. See the
[OSPF Watcher log format](ospf-watcher.md#event-log-format) for a field-by-field
breakdown.

---

**Related:** [OSPF Watcher](ospf-watcher.md) ·
[Traffic Engineering](../analysis/traffic-engineering.md) ·
[ELK / Kibana](elk-kibana.md)

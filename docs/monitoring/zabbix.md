# Zabbix Integration

If Zabbix is your alerting system of record, the Watchers can raise **alarms** on
topology changes — a neighbor lost, a transit-link cost changed, a network
withdrawn — right alongside the rest of your monitoring.

!!! note "Requires Logstash"
    The Zabbix path uses the default (Logstash) profile. It is **not** available
    with the Fluent Bit profile.

## What gets alarmed

The Watcher ships ready-made Zabbix definitions under `docs/zabbix-ui/`. Four
hosts/items (same name on host and item) are expected:

| Item | Fires when… |
| --- | --- |
| `ospf_neighbor_up_down` | A new adjacency forms, or a device loses its neighbor |
| `ospf_network_up_down` | A network is announced or withdrawn from a node |
| `ospf_link_cost_change` | The cost of a transit link (between active neighbors) changes |
| `ospf_stub_network_cost_change` | The cost of a stub network changes |

!!! info "Why transit-link cost matters"
    Transit links connect active neighbors, so a cost change there can shift the
    actual/shortest paths your traffic follows — exactly the kind of change you
    want an alarm on.

The **IS-IS Watcher** provides the equivalent IS-IS items (neighbor up/down, cost
change on transit links, network withdrawal), sharing the same template set.

## Setting it up

1. Import the host/item/trigger definitions from the Watcher's `docs/zabbix-ui/`
   directory into your Zabbix server.
2. Point the Watcher's export at Zabbix (configured through the Logstash
   pipeline / `.env`).
3. Drive a change in a lab (or wait for a real one) and confirm the alarm
   appears on your Zabbix dashboard.

Once configured, active topology alarms detected by the Watcher show up on the
Zabbix dashboard like any other problem, with the latest-data view exposing the
underlying event values.

---

**Related:** [ELK / Kibana](elk-kibana.md) · [Webhooks & Slack](webhooks.md) ·
[OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)

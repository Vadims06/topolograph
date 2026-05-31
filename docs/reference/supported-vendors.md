# Supported Vendors

Topolograph builds a graph from the Link-State Database of a single device. Use
the commands below to capture the LSDB, then
[upload it](../ingestion/text-file.md).

## OSPF (OSPFv2)

| Vendor | LSA 1 (router) | LSA 2 (network) | LSA 5 (external) | SDK SSH driver |
| --- | --- | --- | --- | :---: |
| Cisco | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ |
| Cisco NX-OS | `show ip ospf database router detail` | `show ip ospf database network detail` | `show ip ospf database external detail` | ✅ |
| Quagga | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ |
| Ruckus | `show ip ospf database link-state router` | `show ip ospf database link-state network` | `show ip ospf database external-link-state` | ✅ |
| Juniper | `show ospf database router extensive \| no-more` | `show ospf database network extensive \| no-more` | `show ospf database external extensive \| no-more` | ✅ |
| Bird | `show ospf state all` | `show ospf state all` | `show ospf state all` | ✅ |
| Nokia | `show router ospf database type router detail` | `show router ospf database type network detail` | `show router ospf database type external detail` | ✅ |
| MikroTik | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` | ✅ |
| Huawei | `display ospf lsdb router` | `display ospf lsdb network` | `display ospf lsdb ase` | ✅ |
| Palo Alto | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | ✅ |
| Ubiquiti[^ubnt] | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ |
| Allied Telesis | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ |
| Extreme | `show ospf lsdb detail lstype router` | `show ospf lsdb detail lstype network` | `show ospf lsdb detail lstype as-external` | ✅ |
| Ericsson | `show ospf database router detail` | `show ospf database network detail` | `show ospf database external detail` | ✅ |
| Fortinet | `get router info ospf database router lsa` | `get router info ospf database network lsa` | `get router info ospf database external lsa` | ✅ |
| FRRouting | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ |

[^ubnt]: Applies to the EdgeRouter line and older UniFi USG gateways. Newer UniFi
    gateways use the [FRRouting](https://frrouting.org) project.

!!! tip "Optional TE data (FRRouting)"
    Append `show ip ospf database opaque-area` to the same file for bandwidth, TE
    metric and admin-group data. The graph still builds from LSA 1/2/5 alone. See
    [Traffic Engineering](../analysis/traffic-engineering.md).

## OSPFv3

| Vendor | Command | Stub network | External (redistributed) |
| --- | --- | :---: | :---: |
| Arista | `show ipv6 ospf database detail` | ✅ | ✅ |

## IS-IS

| Vendor | Command | Stub network | External (redistributed) |
| --- | --- | --- | --- |
| Cisco | `show isis database detail` | ✅ | Not yet (needs a tested LSDB) |
| Juniper | `show isis database extensive` | ✅ (needs a tested LSDB to confirm) | Not yet (needs a tested LSDB) |
| Nokia | `show router isis database detail` | ✅ (needs a tested LSDB to confirm) | Not yet (needs a tested LSDB) |
| Huawei | `display isis lsdb verbose` | ✅ (needs a tested LSDB to confirm) | Not yet (needs a tested LSDB) |
| ZTE | `show isis database verbose` | ✅ (needs a tested LSDB to confirm) | Not yet (needs a tested LSDB) |

!!! info "Have an unsupported case?"
    Several IS-IS scenarios are marked "needs a tested LSDB" — if you can share a
    sample database, support can be added. Open an issue on the relevant repo.

## IS-IS TLV support { #is-is-tlv-support }

The IS-IS parser (used by Topolograph and the [IS-IS Watcher](../monitoring/isis-watcher.md))
understands the following TLVs:

| TLV | # | Cisco | Juniper | Nokia | FRR | Huawei | ZTE |
| --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| IS Reachability | 2 | ✅ | ✅ | ✅ | ✅ | | ✅ |
| Extended IS Reachability (new) | 22 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv4 Internal Reachability (old) | 128 | ✅ | ✅ | ✅ | ✅ | ✅ | |
| IPv4 External Reachability (old) | 130 | | | | | | |
| Extended IPv4 Reachability (new) | 135 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv6 Reachability | 236 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Both **narrow** (old-style) and **wide** (new-style) metrics are parsed. Wide
metrics carry TE attributes — see [Traffic Engineering](../analysis/traffic-engineering.md).

## Ingestion via BGP-LS

Beyond text files, OSPF and IS-IS topology can be ingested live over **BGP-LS**
using the matching Watcher. See [BGP-LS session](../ingestion/bgp-ls.md).

---

The canonical, interactive API schema is always available at `/api/ui/` on your
instance.

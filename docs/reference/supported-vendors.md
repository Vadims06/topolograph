# Supported Vendors

Topolograph builds a graph from the Link-State Database of a single device. Use
the commands below to capture the LSDB, then
[upload it](../ingestion/text-file.md).

## OSPF (OSPFv2)

| Vendor | LSA 1 (router) | LSA 2 (network) | LSA 5 (external) | Node flags (ABR/ASBR) | SDK SSH driver |
| --- | --- | --- | --- | :---: | :---: |
| Cisco | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ | ✅ |
| Cisco NX-OS | `show ip ospf database router detail` | `show ip ospf database network detail` | `show ip ospf database external detail` | ✅ | ✅ |
| Quagga | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ | ✅ |
| Ruckus | `show ip ospf database link-state router` | `show ip ospf database link-state network` | `show ip ospf database external-link-state` | | ✅ |
| Juniper | `show ospf database router extensive \| no-more` | `show ospf database network extensive \| no-more` | `show ospf database external extensive \| no-more` | ✅ | ✅ |
| Bird | `show ospf state all` | `show ospf state all` | `show ospf state all` | | ✅ |
| Nokia | `show router ospf database type router detail` | `show router ospf database type network detail` | `show router ospf database type external detail` | | ✅ |
| MikroTik | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` | ✅[^mt-flags] | ✅ |
| Huawei | `display ospf lsdb router` | `display ospf lsdb network` | `display ospf lsdb ase` | ✅ | ✅ |
| IP Infusion OcNOS | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ | |
| Palo Alto | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | | ✅ |
| Ubiquiti[^ubnt] | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | | ✅ |
| Allied Telesis | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | | ✅ |
| Extreme | `show ospf lsdb detail lstype router` | `show ospf lsdb detail lstype network` | `show ospf lsdb detail lstype as-external` | | ✅ |
| Ericsson | `show ospf database router detail` | `show ospf database network detail` | `show ospf database external detail` | | ✅ |
| Fortinet | `get router info ospf database router lsa` | `get router info ospf database network lsa` | `get router info ospf database external lsa` | | ✅ |
| FRRouting | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ | ✅ |

[^ubnt]: Applies to the EdgeRouter line and older UniFi USG gateways. Newer UniFi
    gateways use the [FRRouting](https://frrouting.org) project.

[^mt-flags]: RouterOS 7.18 and newer, which prints the `bits=` field in the LSA dump.

!!! info "Node flags (ABR/ASBR)"
    Routers advertising the B (Area Border Router) or E (AS Boundary Router) bit
    in their Router-LSA are detected and shown on the node's hover tooltip. The
    flag is also queryable on the nodes API (`?abr=1`, `?asbr=1`). The same flags
    are reported live by the [OSPF Watcher](../monitoring/ospf-watcher.md).

!!! tip "Optional TE data (FRRouting)"
    Append `show ip ospf database opaque-area` to the same file for bandwidth, TE
    metric and admin-group data. The graph still builds from LSA 1/2/5 alone. See
    [Traffic Engineering](../analysis/traffic-engineering.md).

!!! tip "Optional TE data (IP Infusion OcNOS)"
    Append `show ip ospf database opaque-area` to the same file for TE link
    attributes. The graph still builds from LSA 1/2/5 alone.

## OSPFv3

| Vendor | Command | Stub network | External (redistributed) |
| --- | --- | :---: | :---: |
| Arista | `show ipv6 ospf database detail` | ✅ | ✅ |
| IP Infusion OcNOS | `show ipv6 ospf database router`, `network`, `external`, `intra-prefix` | ✅ | ✅ |
| Fortinet FortiOS | `get router info6 ospf database router`, `network`, `external`, `intra-prefix` | ✅ | ✅ |
| MikroTik RouterOS | `/routing/ospf/lsa/print detail without-paging where instance=v3` | ✅ | ✅ |

!!! note
    OcNOS and FortiOS need the per-LSA-type forms: the bare `show ipv6 ospf database` / `get router info6 ospf database` prints only an index table, and `intra-prefix` is mandatory because OSPFv3 carries prefixes only in that LSA.

## IS-IS

| Vendor | Command | Stub network | External (redistributed) | Node flags (OL/ATT) |
| --- | --- | --- | --- | :---: |
| Cisco | `show isis database detail` | ✅ | Not yet (needs an LSDB sample) | ✅ |
| Juniper | `show isis database extensive` | ✅ (needs an LSDB sample to confirm) | Not yet (needs an LSDB sample) | ✅ (needs an LSDB sample to confirm) |
| Nokia | `show router isis database detail` | ✅ (needs an LSDB sample to confirm) | Not yet (needs an LSDB sample) | ✅ (needs an LSDB sample to confirm) |
| Huawei | `display isis lsdb verbose` | ✅ (needs an LSDB sample to confirm) | Not yet (needs an LSDB sample) | ✅ (needs an LSDB sample to confirm) |
| ZTE | `show isis database verbose` | ✅ (needs an LSDB sample to confirm) | Not yet (needs an LSDB sample) | ✅ (needs an LSDB sample to confirm) |
| FRRouting | `show isis database detail` | ✅ | Not yet (needs an LSDB sample) | ✅ |
| IP Infusion OcNOS | `show isis database verbose` | ✅ | ✅ | ✅ |
| Fortinet FortiOS | `get router info isis database detail` | ✅ | ✅ | ✅ (needs an LSDB sample to confirm) |
| MikroTik RouterOS | `/routing/isis/lsp/print detail without-paging` | ✅ | ✅ | |

!!! info "Node flags (overload / attached)"
    Overload (OL) and attached (ATT) are read from each LSP's `ATT/P/OL` column on
    text-file upload, and are also reported live by the
    [IS-IS Watcher](../monitoring/isis-watcher.md) (which additionally derives
    ABR/ASBR over BGP-LS).

!!! info "Have an unsupported case?"
    Several IS-IS scenarios are marked "needs an LSDB sample" — if you can share a
    sample database, support can be added. Open an issue on the relevant repo.

## IS-IS TLV support { #is-is-tlv-support }

The IS-IS parser (used by Topolograph and the [IS-IS Watcher](../monitoring/isis-watcher.md))
understands the following TLVs:

| TLV | # | RFC | Cisco | Juniper | Nokia | FRR | Huawei | ZTE | MikroTik |
| --- | :-: | --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| IS Reachability | 2 | ISO 10589 | ✅ | ✅ | ✅ | ✅ |  | ✅ | ✅ |
| Extended IS Reachability (new) | 22 | RFC 5305 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv4 Internal Reachability (old) | 128 | RFC 1195 | ✅ | ✅ | ✅ | ✅ | ✅ |  | ✅ |
| IPv4 External Reachability (old) | 130 | RFC 1195 |  |  |  |  |  |  |  |
| Extended IPv4 Reachability (new) | 135 | RFC 5305 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv6 Reachability | 236 | RFC 5308 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Both **narrow** (old-style) and **wide** (new-style) metrics are parsed. Wide
metrics carry TE attributes — see [Traffic Engineering](../analysis/traffic-engineering.md).

## TE attributes by vendor { #te-attributes-by-vendor }

What each vendor's parser turns into link attributes. A blank cell means the attribute is not read from that output, even when the router advertises it. A [Watcher](../monitoring/isis-watcher.md) or BGP-LS session carries every attribute the router advertises.

### IS-IS { #te-is-is }

| TE attribute | API/SDK name | Defined in | FRR | Nokia | ZTE | OcNOS |
| --- | --- | --- | :-: | :-: | :-: | :-: |
| TE default metric | `temetric` | RFC 5305 §3.7, sub-TLV 18 | ✅ | ✅ |  | ✅ |
| Administrative group | `admin_group` | RFC 5305 §3.1, sub-TLV 3 | ✅ | ✅ | ✅ |  |
| Maximum link bandwidth | `max_link_bw` | RFC 5305 §3.4, sub-TLV 9 | ✅ | ✅ | ✅ |  |
| Maximum reservable bandwidth | `max_rsrv_link_bw` | RFC 5305 §3.5, sub-TLV 10 | ✅ | ✅ | ✅ |  |
| Unreserved bandwidth (per priority) | `unreserved_bw_0` … `unreserved_bw_7` | RFC 5305 §3.6, sub-TLV 11 | ✅ | ✅ | ✅ |  |
| Shared risk link group | `srlg` | RFC 5307 §1.2, TLV 138 | ✅ |  |  |  |
| Interface / neighbor address | `local_ip_address`, `remote_ip_address` | RFC 5305 §3.2, §3.3, sub-TLVs 6 / 8 | ✅ | ✅ | ✅ |  |
| Link local / remote ID | `link_local_id`, `link_remote_id` | RFC 5307 §1.1, sub-TLV 4 |  |  | ✅ |  |

Commands that print the sub-TLVs: `show isis database detail` (FRR), `show router isis database detail` (Nokia SR OS), `show isis database verbose` (ZTE, IP Infusion OcNOS). OcNOS prints the TE sub-TLVs only with `verbose`, not with `detail`.

!!! note
    FRR prints SRLG only in builds that include [FRRouting/frr#22392](https://github.com/FRRouting/frr/pull/22392).

### OSPF { #te-ospf }

| TE attribute | API/SDK name | Defined in | FRR | OcNOS |
| --- | --- | --- | :-: | :-: |
| TE default metric | `temetric` | RFC 3630 §2.5.5, sub-TLV 5 | ✅ | ✅ |
| Administrative group | `admin_group` | RFC 3630 §2.5.9, sub-TLV 9 | ✅ |  |
| Maximum link bandwidth | `max_link_bw` | RFC 3630 §2.5.6, sub-TLV 6 | ✅ |  |
| Maximum reservable bandwidth | `max_rsrv_link_bw` | RFC 3630 §2.5.7, sub-TLV 7 | ✅ |  |
| Unreserved bandwidth (per priority) | `unreserved_bw_0` … `unreserved_bw_7` | RFC 3630 §2.5.8, sub-TLV 8 | ✅ |  |
| Shared risk link group | `srlg` | RFC 4203 §1.3, sub-TLV 16 |  |  |
| Local / remote interface address | `local_ip_address`, `remote_ip_address` | RFC 3630 §2.5.3, §2.5.4, sub-TLVs 3 / 4 | ✅ | ✅ |

Append `show ip ospf database opaque-area` to the same upload file. OcNOS prints the TE metric as `Admin Metric`.

## Supported RFCs { #supported-rfcs }

RFCs implemented in the parsers and calculations of Topolograph.

| Protocol | RFC | What Topolograph reads |
| --- | --- | --- |
| OSPFv2 | RFC 2328 | Router (1), Network (2) and AS-External (5) LSAs |
| OSPFv2 | RFC 3630 | TE link attributes from opaque-area LSAs (type 10) |
| OSPFv2 | RFC 4203 | Shared risk link group (SRLG), when the values arrive from a Watcher |
| OSPFv2 | RFC 6987 | Stub router (max-metric) flag on nodes |
| OSPFv3 | RFC 5340 | Router, Network, AS-External and Intra-Area-Prefix LSAs |
| IS-IS | ISO/IEC 10589 | IS Reachability (TLV 2), Level 1 / Level 2 databases, overload and attached bits |
| IS-IS | RFC 1195 | IPv4 Internal Reachability (TLV 128) |
| IS-IS | RFC 5305 | Extended IS and IPv4 Reachability (TLVs 22, 135) and TE sub-TLVs |
| IS-IS | RFC 5307 | Shared risk link group (TLV 138) and link local / remote identifiers |
| IS-IS | RFC 5308 | IPv6 Reachability (TLV 236) |
| MPLS TE | RFC 3209 | Setup and holding priorities in CSPF placement of LSP tunnels |
| BGP | RFC 4271, RFC 4456, RFC 4364 | Best-path selection, route reflection and VPN routes |
| BGP | RFC 7854, RFC 8671, RFC 9069 | BMP: Adj-RIB-In / Adj-RIB-Out and Loc-RIB |

## Ingestion via BGP-LS

Beyond text files, OSPF and IS-IS topology can be ingested live over **BGP-LS**
using the matching Watcher. See [BGP-LS session](../ingestion/bgp-ls.md).

---

The canonical, interactive API schema is always available at `/api/ui/` on your
instance.

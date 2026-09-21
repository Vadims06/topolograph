# 支持的厂商

Topolograph 从单台设备的链路状态数据库构建图。使用下面的命令采集 LSDB，
然后[上传它](../ingestion/text-file.md)。

## OSPF (OSPFv2)

| 厂商 | LSA 1（router） | LSA 2（network） | LSA 5（external） | 节点标志（ABR/ASBR） | SDK SSH 驱动 |
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
| Palo Alto | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | | ✅ |
| Ubiquiti[^ubnt] | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | | ✅ |
| Allied Telesis | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | | ✅ |
| Extreme | `show ospf lsdb detail lstype router` | `show ospf lsdb detail lstype network` | `show ospf lsdb detail lstype as-external` | | ✅ |
| Ericsson | `show ospf database router detail` | `show ospf database network detail` | `show ospf database external detail` | | ✅ |
| Fortinet | `get router info ospf database router lsa` | `get router info ospf database network lsa` | `get router info ospf database external lsa` | | ✅ |
| FRRouting | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ | ✅ |

[^ubnt]: 适用于 EdgeRouter 系列以及较旧的 UniFi USG 网关。较新的 UniFi
    网关使用 [FRRouting](https://frrouting.org) 项目。

[^mt-flags]: RouterOS 7.18 及更新版本，会在 LSA 转储中打印 `bits=` 字段。

!!! info "节点标志（ABR/ASBR）"
    在 Router-LSA 中通告 B（区域边界路由器）或 E（AS 边界路由器）位的路由器
    会被检测到，并显示在该节点的悬停提示中。该标志也可以通过节点 API 查询
    （`?abr=1`、`?asbr=1`）。[OSPF Watcher](../monitoring/ospf-watcher.md)
    会实时上报相同的标志。

!!! tip "可选的 TE 数据（FRRouting）"
    将 `show ip ospf database opaque-area` 追加到同一个文件中，即可获取带宽、
    TE 度量和管理组数据。没有它，图仍然可以仅凭 LSA 1/2/5 构建。参见
    [流量工程](../analysis/traffic-engineering.md)。

## OSPFv3

| 厂商 | 命令 | Stub 网络 | External（重分发） |
| --- | --- | :---: | :---: |
| Arista | `show ipv6 ospf database detail` | ✅ | ✅ |
| IP Infusion OcNOS | `show ipv6 ospf database router`, `network`, `external`, `intra-prefix` | ✅ | ✅ |
| Fortinet FortiOS | `get router info6 ospf database router`, `network`, `external`, `intra-prefix` | ✅ | ✅ |
| MikroTik RouterOS | `/routing/ospf/lsa/print detail without-paging where instance=v3` | ✅ | ✅ |

!!! note
    OcNOS 和 FortiOS 需要按 LSA 类型分别执行命令：不带类型的 `show ipv6 ospf database` / `get router info6 ospf database` 只输出索引表，而且必须包含 `intra-prefix`，因为 OSPFv3 只在该 LSA 中携带前缀。

## IS-IS

| 厂商 | 命令 | Stub 网络 | External（重分发） | 节点标志（OL/ATT） |
| --- | --- | --- | --- | :---: |
| Cisco | `show isis database detail` | ✅ | 尚不支持（需要 LSDB 示例） | ✅ |
| Juniper | `show isis database extensive` | ✅（需要 LSDB 示例 以确认） | 尚不支持（需要 LSDB 示例） | ✅（需要 LSDB 示例 以确认） |
| Nokia | `show router isis database detail` | ✅（需要 LSDB 示例 以确认） | 尚不支持（需要 LSDB 示例） | ✅（需要 LSDB 示例 以确认） |
| Huawei | `display isis lsdb verbose` | ✅（需要 LSDB 示例 以确认） | 尚不支持（需要 LSDB 示例） | ✅（需要 LSDB 示例 以确认） |
| ZTE | `show isis database verbose` | ✅（需要 LSDB 示例 以确认） | 尚不支持（需要 LSDB 示例） | ✅（需要 LSDB 示例 以确认） |
| FRRouting | `show isis database detail` | ✅ | 尚不支持（需要 LSDB 示例） | ✅ |
| IP Infusion OcNOS | `show isis database verbose` | ✅ | ✅ | ✅ |
| Fortinet FortiOS | `get router info isis database detail` | ✅ | ✅ | ✅（需要 LSDB 示例 以确认） |
| MikroTik RouterOS | `/routing/isis/lsp/print detail without-paging` | ✅ | ✅ | |

!!! info "节点标志（overload / attached）"
    Overload（OL）和 attached（ATT）是在文本文件上传时从每条 LSP 的
    `ATT/P/OL` 列中读取的，并且也由
    [IS-IS Watcher](../monitoring/isis-watcher.md) 实时上报（该工具还会
    通过 BGP-LS 额外推导出 ABR/ASBR）。

!!! info "遇到了不支持的情况？"
    有若干 IS-IS 场景被标记为"需要 LSDB 示例"——如果您能提供一份样例
    数据库，就可以添加相应支持。请在对应代码仓库中提交一个 issue。

## IS-IS TLV 支持 { #is-is-tlv-support }

IS-IS 解析器（被 Topolograph 和 [IS-IS Watcher](../monitoring/isis-watcher.md)
使用）理解以下 TLV：

| TLV | # | RFC | Cisco | Juniper | Nokia | FRR | Huawei | ZTE | MikroTik |
| --- | :-: | --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| IS Reachability | 2 | ISO 10589 | ✅ | ✅ | ✅ | ✅ |  | ✅ | ✅ |
| Extended IS Reachability (new) | 22 | RFC 5305 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv4 Internal Reachability (old) | 128 | RFC 1195 | ✅ | ✅ | ✅ | ✅ | ✅ |  | ✅ |
| IPv4 External Reachability (old) | 130 | RFC 1195 |  |  |  |  |  |  |  |
| Extended IPv4 Reachability (new) | 135 | RFC 5305 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv6 Reachability | 236 | RFC 5308 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

**narrow**（旧式）和 **wide**（新式）度量都会被解析。Wide 度量携带 TE 属性——
参见[流量工程](../analysis/traffic-engineering.md)。

## 各厂商的 TE 属性 { #te-attributes-by-vendor }

各厂商解析器会把哪些内容转换为链路属性。空单元格表示该属性不会从对应输出中读取，即使路由器已通告它。[Watcher](../monitoring/isis-watcher.md) 或 BGP-LS 会话会携带路由器通告的全部属性。

### IS-IS { #te-is-is }

| TE 属性 | API/SDK 名称 | 定义于 | FRR | Nokia | ZTE | OcNOS |
| --- | --- | --- | :-: | :-: | :-: | :-: |
| TE 默认度量 | `temetric` | RFC 5305 §3.7, sub-TLV 18 | ✅ | ✅ |  | ✅ |
| 管理组 | `admin_group` | RFC 5305 §3.1, sub-TLV 3 | ✅ | ✅ | ✅ |  |
| 最大链路带宽 | `max_link_bw` | RFC 5305 §3.4, sub-TLV 9 | ✅ | ✅ | ✅ |  |
| 最大可预留带宽 | `max_rsrv_link_bw` | RFC 5305 §3.5, sub-TLV 10 | ✅ | ✅ | ✅ |  |
| 未预留带宽（按优先级） | `unreserved_bw_0` … `unreserved_bw_7` | RFC 5305 §3.6, sub-TLV 11 | ✅ | ✅ | ✅ |  |
| 共享风险链路组 | `srlg` | RFC 5307 §1.2, TLV 138 | ✅ |  |  |  |
| 接口 / 邻居地址 | `local_ip_address`, `remote_ip_address` | RFC 5305 §3.2, §3.3, sub-TLVs 6 / 8 | ✅ | ✅ | ✅ |  |
| 链路本地 / 远端 ID | `link_local_id`, `link_remote_id` | RFC 5307 §1.1, sub-TLV 4 |  |  | ✅ |  |

输出 sub-TLV 的命令：`show isis database detail`（FRR）、`show router isis database detail`（Nokia SR OS）、`show isis database verbose`（ZTE、IP Infusion OcNOS）。OcNOS 只有使用 `verbose`（而不是 `detail`）才会输出 TE sub-TLV。

!!! note
    只有包含 [FRRouting/frr#22392](https://github.com/FRRouting/frr/pull/22392) 的 FRR 版本才会输出 SRLG。

### OSPF { #te-ospf }

| TE 属性 | API/SDK 名称 | 定义于 | FRR | OcNOS |
| --- | --- | --- | :-: | :-: |
| TE 默认度量 | `temetric` | RFC 3630 §2.5.5, sub-TLV 5 | ✅ | ✅ |
| 管理组 | `admin_group` | RFC 3630 §2.5.9, sub-TLV 9 | ✅ |  |
| 最大链路带宽 | `max_link_bw` | RFC 3630 §2.5.6, sub-TLV 6 | ✅ |  |
| 最大可预留带宽 | `max_rsrv_link_bw` | RFC 3630 §2.5.7, sub-TLV 7 | ✅ |  |
| 未预留带宽（按优先级） | `unreserved_bw_0` … `unreserved_bw_7` | RFC 3630 §2.5.8, sub-TLV 8 | ✅ |  |
| 共享风险链路组 | `srlg` | RFC 4203 §1.3, sub-TLV 16 |  |  |
| 本地 / 远端接口地址 | `local_ip_address`, `remote_ip_address` | RFC 3630 §2.5.3, §2.5.4, sub-TLVs 3 / 4 | ✅ | ✅ |

将 `show ip ospf database opaque-area` 追加到同一个上传文件中。OcNOS 将 TE 度量输出为 `Admin Metric`。

## 支持的 RFC { #supported-rfcs }

Topolograph 的解析器和计算中已实现的 RFC。

| 协议 | RFC | Topolograph 读取的内容 |
| --- | --- | --- |
| OSPFv2 | RFC 2328 | Router (1)、Network (2) 和 AS-External (5) LSA |
| OSPFv2 | RFC 3630 | 来自 opaque-area LSA（类型 10）的 TE 链路属性 |
| OSPFv2 | RFC 4203 | 共享风险链路组（SRLG），当数值来自 Watcher 时 |
| OSPFv2 | RFC 6987 | 节点上的 stub router（max-metric）标志 |
| OSPFv3 | RFC 5340 | Router、Network、AS-External 和 Intra-Area-Prefix LSA |
| IS-IS | ISO/IEC 10589 | IS Reachability（TLV 2）、Level 1 / Level 2 数据库、overload 与 attached 位 |
| IS-IS | RFC 1195 | IPv4 Internal Reachability（TLV 128） |
| IS-IS | RFC 5305 | Extended IS 与 IPv4 Reachability（TLV 22、135）以及 TE sub-TLV |
| IS-IS | RFC 5307 | 共享风险链路组（TLV 138）以及链路本地 / 远端标识 |
| IS-IS | RFC 5308 | IPv6 Reachability（TLV 236） |
| MPLS TE | RFC 3209 | LSP 隧道 CSPF 放置中的 setup 与 holding 优先级 |
| BGP | RFC 4271, RFC 4456, RFC 4364 | 最佳路径选择、路由反射和 VPN 路由 |
| BGP | RFC 7854, RFC 8671, RFC 9069 | BMP：Adj-RIB-In / Adj-RIB-Out 与 Loc-RIB |

## 通过 BGP-LS 导入

除了文本文件之外，OSPF 和 IS-IS 拓扑还可以使用对应的 Watcher 通过
**BGP-LS** 实时导入。参见 [BGP-LS 会话](../ingestion/bgp-ls.md)。

---

权威的、可交互的 API 模式（schema）始终可以在您实例的 `/api/ui/` 上查看。

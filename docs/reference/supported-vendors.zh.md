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

## IS-IS

| 厂商 | 命令 | Stub 网络 | External（重分发） | 节点标志（OL/ATT） |
| --- | --- | --- | --- | :---: |
| Cisco | `show isis database detail` | ✅ | 尚不支持（需要经过测试的 LSDB） | ✅ |
| Juniper | `show isis database extensive` | ✅（需要经过测试的 LSDB 以确认） | 尚不支持（需要经过测试的 LSDB） | ✅（需要经过测试的 LSDB 以确认） |
| Nokia | `show router isis database detail` | ✅（需要经过测试的 LSDB 以确认） | 尚不支持（需要经过测试的 LSDB） | ✅（需要经过测试的 LSDB 以确认） |
| Huawei | `display isis lsdb verbose` | ✅（需要经过测试的 LSDB 以确认） | 尚不支持（需要经过测试的 LSDB） | ✅（需要经过测试的 LSDB 以确认） |
| ZTE | `show isis database verbose` | ✅（需要经过测试的 LSDB 以确认） | 尚不支持（需要经过测试的 LSDB） | ✅（需要经过测试的 LSDB 以确认） |

!!! info "节点标志（overload / attached）"
    Overload（OL）和 attached（ATT）是在文本文件上传时从每条 LSP 的
    `ATT/P/OL` 列中读取的，并且也由
    [IS-IS Watcher](../monitoring/isis-watcher.md) 实时上报（该工具还会
    通过 BGP-LS 额外推导出 ABR/ASBR）。

!!! info "遇到了不支持的情况？"
    有若干 IS-IS 场景被标记为"需要经过测试的 LSDB"——如果您能提供一份样例
    数据库，就可以添加相应支持。请在对应代码仓库中提交一个 issue。

## IS-IS TLV 支持 { #is-is-tlv-support }

IS-IS 解析器（被 Topolograph 和 [IS-IS Watcher](../monitoring/isis-watcher.md)
使用）理解以下 TLV：

| TLV | # | Cisco | Juniper | Nokia | FRR | Huawei | ZTE |
| --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| IS Reachability | 2 | ✅ | ✅ | ✅ | ✅ | | ✅ |
| Extended IS Reachability（新式） | 22 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv4 Internal Reachability（旧式） | 128 | ✅ | ✅ | ✅ | ✅ | ✅ | |
| IPv4 External Reachability（旧式） | 130 | | | | | | |
| Extended IPv4 Reachability（新式） | 135 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv6 Reachability | 236 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

**narrow**（旧式）和 **wide**（新式）度量都会被解析。Wide 度量携带 TE 属性——
参见[流量工程](../analysis/traffic-engineering.md)。

## 通过 BGP-LS 导入

除了文本文件之外，OSPF 和 IS-IS 拓扑还可以使用对应的 Watcher 通过
**BGP-LS** 实时导入。参见 [BGP-LS 会话](../ingestion/bgp-ls.md)。

---

权威的、可交互的 API 模式（schema）始终可以在您实例的 `/api/ui/` 上查看。

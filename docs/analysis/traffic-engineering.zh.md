# 流量工程（TE）

除了基本的 IGP 开销之外，OSPF 和 IS-IS 还可以携带**流量工程**属性——带宽、
独立的 TE 度量，以及管理组/affinity。Topolograph 会解析这些属性，并为
**OSPF** 和 **IS-IS** 提供更丰富的可视化和筛选能力。

!!! info "TE 是可选的"
    仅凭普通的 LSA 1/2/5（OSPF）或标准的 IS-IS LSDB，您的图就能正常构建。
    TE 数据是*额外*的——当您需要容量感知分析时再启用它。

## Topolograph 解析哪些内容 { #what-topolograph-parses }

| 属性 | API/SDK 名称 | 含义 |
| --- | --- | --- |
| TE 默认度量 | `temetric` | TE 专用的链路度量（独立于 IGP 开销） |
| 管理组 | `admin_group` | Affinity / 颜色 / 资源类别 |
| 最大链路带宽 | `max_link_bw` | 物理链路容量 |
| 最大可预留带宽 | `max_rsrv_link_bw` | 可用于预留的带宽 |
| 未预留带宽（按优先级） | `unreserved_bw_0` … `unreserved_bw_7` | 8 个 TE 优先级各自的剩余带宽 |
| 共享风险链路组 | `srlg` | 该链路所属的 SRLG id 列表（RFC 4203 / RFC 5307） |

无论数据来自 OSPF 还是 IS-IS，都使用**相同的属性名称**。

## 如何导入 TE 数据

=== "OSPF — 文本文件"

    在与您的路由器/网络/外部 LSDB 相同的上传文件中包含
    **`show ip ospf database opaque-area`**。Type-10（opaque-area）LSA 携带
    TE 数据；图的其余部分照常由 LSA 1、2 和 5 构建。

    [:octicons-arrow-right-24: 上传文本文件](../ingestion/text-file.md)

=== "IS-IS — 文本文件"

    当您使用标准的详细命令（例如 FRR 的 **`show isis database detail`**）时，
    TE 属性直接来自 IS-IS LSDB。除正常的 IS-IS 采集之外，无需额外命令。

=== "OSPF / IS-IS — BGP-LS"

    **BGP-LS 原生携带 TE 属性**——管理组、最大带宽和可预留带宽、未预留带宽、
    SRLG，以及 TE 默认度量——无需借助 opaque-LSA 技巧。TE 更新会实时流入监控视图。

    [:octicons-arrow-right-24: BGP-LS 会话](../ingestion/bgp-ls.md)

当 TE 数据通过 BGP-LS 到达时，监控页面会随着更新的到来展示链路属性：

![通过 BGP-LS 在监控页面上显示的 TE 链路属性](../static/te_link_attributes_on_monitoring_page_full_with_bgpls_1.png)

## 按 TE 属性筛选链路

一旦拓扑图具有 TE 数据，您就可以使用范围运算符 `__gt`、`__lt`、`__gte`、`__lte`
按任意 TE 属性查询链路——便于查找违反（或满足）某个 TE 约束的链路。使用
[Python SDK](../automation/python-sdk.md)：

```python
# TE 度量 >= 100 的链路
edges = graph.edges_list(temetric__gte=100)

# 优先级 0 处未预留带宽低于 1 Gbps 的链路
edges = graph.edges_list(unreserved_bw_0__lt=1e9)

# 两个节点之间最大链路带宽高于 10 Gbps 的链路
edges = graph.edges_list(src_node="1.1.1.1", dst_node="2.2.2.2", max_link_bw__gt=1e10)
```

相同的筛选功能也可以通过拓扑图链路 REST API 使用。

## IS-IS 特性

IS-IS TE 依赖 **wide metrics**（Extended IS/IP Reachability，TLV 22/135），
并支持 **IPv6** 可达性（TLV 236）。相关 TLV 的厂商支持情况汇总在
[支持的厂商](../reference/supported-vendors.md#is-is-tlv-support)页面。

## 监控 TE 变化

当 Watcher 连接后，TE 属性的变化会与开销和邻接关系的变化一起被捕获为事件——
参见 [ELK / Kibana](../monitoring/elk-kibana.md) 中的 `te_log` 视图，以及
[IS-IS Watcher](../monitoring/isis-watcher.md) 页面。

---

**相关内容：**[获取拓扑数据](../ingestion/index.md)·
[可视化与分析](visualizing.md)

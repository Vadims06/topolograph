# IS-IS Watcher

**IS-IS Watcher** 是 [OSPF Watcher](ospf-watcher.md) 的 IS-IS 对应版本。它通过
[GRE 邻接关系](../ingestion/gre.md)或 [BGP-LS](../ingestion/bgp-ls.md)被动监听
IS-IS 控制平面——记录并/或导出每一次变化到 **ELK**、**Zabbix**、**WebHooks**，
以及 **Topolograph** 监控仪表盘。与 OSPF Watcher 一样，它以容器形式提供。

[:simple-github: vadims06/isiswatcher](https://github.com/Vadims06/isiswatcher){ .md-button }

![IS-IS Watcher + Topolograph 架构](../assets/isiswatcher_architecture.png)

## 检测到的事件

- IS-IS 邻居邻接关系 **Up/Down**
- IS-IS 链路**开销变化**
- IS-IS 网络的**出现/消失**
- IS-IS **TE 属性**：管理组、最大链路带宽、最大可预留带宽、未预留带宽、
  TE 默认度量，以及共享风险链路组（SRLG）
- IS-IS **节点标志**：**overload（OL）**和 **attached（ATT）**的转换
  （加上通过 BGP-LS 推导出的 ABR/ASBR）

在时间线上，所有内容都按 **IS-IS 级别（L1/L2）**分组：

![带有 L1/L2 IS-IS 事件的 Topolograph 仪表盘](../assets/dashboard_l1_l2_events.png)

!!! example "各级别看起来是什么样子"
    一次典型的采集可能会显示：某条链路上的度量变化在 **L1 和 L2 上都出现了
    重复日志**；应用 `isis circuit-type level-1` 后，一台路由器**仅在 L2 上
    下线**；随后的一次度量变化**仅在 L1 中**可见；以及一个新的 stub 网络
    **出现在 L2 中**。

## 建立连接

连接的建立方式记录在[获取拓扑数据](../ingestion/index.md)中：

- [**GRE 模式**](../ingestion/gre.md) —— FRR 通过 GRE 隧道建立 IS-IS 邻接
  关系；**XDP IS-IS 过滤器**通过丢弃任何通告了超出 Watcher 自身网络范围的
  LSP，来保证 Watcher 始终保持仅监听状态。
- [**BGP-LS 模式**](../ingestion/bgp-ls.md) —— 路由器通过 BGP-LS 导出 IS-IS
  拓扑；GoBGP + 转发器为 Watcher 提供数据。

![每个区域独立的 GRE FRR 实例](../assets/gre_frr_instances.png)

!!! warning "每个区域一条 GRE 隧道"
    IS-IS 与 OSPF 一样，按区域/级别进行泛洪。在 GRE 模式下，您需要向
    **每一个要监控的区域至少建立一条 GRE 隧道**——这是链路状态泛洪的固有属性，
    而不是工具的限制。BGP-LS 通过单个会话承载整个域，从而避免了这个问题。

!!! note "兼容性"
    IS-IS 网络变化从
    [topolograph v2.38](https://github.com/Vadims06/topolograph/releases/tag/v2.38)
    或更高版本开始会显示在图上。

## TLV 与度量支持

IS-IS Watcher 同时解析旧式（narrow）和新式（wide）度量，并支持 IPv6 可达性。
它所理解的 TLV——以及各厂商的支持矩阵——汇总在
[支持的厂商](../reference/supported-vendors.md#is-is-tlv-support)页面。

关键 TLV：IS Reachability（2）、Extended IS Reachability（22）、IPv4 Internal/
Extended Reachability（128/135），以及 IPv6 Reachability（236）。

!!! info "定制的 FRR 构建版本"
    通过 GRE 运行 IS-IS 需要一个具备相应能力的 FRR 构建版本；IS-IS Watcher
    代码仓库提供了所需的构建版本。详情请参见
    [代码仓库](https://github.com/Vadims06/isiswatcher)。

## 快速实验环境（containerlab）

该代码仓库附带了一个 containerlab 拓扑，用于端到端体验 IS-IS 监控——参见
`containerlab/` 目录，以及关于如何叠加 Topolograph 和 ELK 的
[部署规模](index.md#deployment-sizes)表格。

!!! tip "没有设备？使用测试模式"
    与 OSPF Watcher 一样，`TEST_MODE` 会从一个静态文件回放演示用的 IS-IS 事件，
    以便您在没有硬件的情况下体验整个流程。

## 事件日志格式

IS-IS Watcher 发出与 OSPF Watcher 相同的逗号分隔事件记录（同时附带 IS-IS
**级别**信息）——因此 [ELK](elk-kibana.md)、[Zabbix](zabbix.md) 和
[Webhook](webhooks.md) 的集成方式完全相同。逐字段的详细说明请参见
[OSPF Watcher 日志格式](ospf-watcher.md#event-log-format)。

---

**相关内容：** [OSPF Watcher](ospf-watcher.md) ·
[流量工程](../analysis/traffic-engineering.md) ·
[ELK / Kibana](elk-kibana.md)

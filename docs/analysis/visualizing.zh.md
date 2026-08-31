# 可视化与分析

这是 Topolograph 的核心：一个交互式 OSPF/IS-IS 图，您可以使用路由器所用的相同算法
对其进行探测。以下所有操作都基于您上传的**快照**运行，因此实验永远不会影响生产网络。

## 最短路径

选择一个源节点和一个目标节点，Topolograph 会在它们之间构建**最短路径树**，
高亮显示路径并展示总 IGP 开销。

![两个节点之间的最短路径树](../static/SPT.png)

当存在多条等开销路径时，系统会明确显示 **ECMP**，让您看到流量在何处进行负载均衡。

![带有 ECMP 路径的拓扑](../static/topology_with_ecmp.png)

## 备份路径

Topolograph 不仅显示主路径——它还会计算主路径发生故障时网络实际会使用的
**备份路径**，包括**次要**备份路径。这回答了每次变更窗口都会提出的问题：
*"如果这条链路故障，流量会流向哪里？"*

![备份最短路径树](../static/backup_SPT.png)

它还会区分经过 ECMP 的备份路径和不经过 ECMP 的备份路径，这在您评估故障期间的
容量时非常重要。

## 模拟故障 { #simulating-failures }

在不触碰任何生产环境的情况下测试"假设"场景。

### 关闭一条链路

移除一条链路，Topolograph 会立即重新计算路径，展示流量如何绕行。

![移除链路后的网络反应](../static/network_reaction_rem_edge1.png)

您可以同时看到结果与受影响的统计数据：

![移除链路后的网络反应及统计数据](../static/network_reaction_rem_edge_with_stat.png)

### 关闭一个节点

模拟整台路由器发生故障，观察流量如何绕过故障节点。右键点击某个节点并选择
**Shutdown this node**。

![关闭节点后的网络反应](../static/network_reaction_shut_node.png)

![关闭节点后的结果](../static/network_reaction_result_on_shut_node.png)

## 规划链路开销

实时更改 IGP 度量，立即查看对路径选择的影响——非常适合规划维护窗口、将流量从
某条链路迁移出去，或在下发之前验证开销设计。

确认您仍处于**网络故障反应**标签页。右键点击某条链路：会出现一个列出链路的表单。
在所需链路旁设置新的度量值；路径重算结果会立即显示在图上。

![OSPF 开销变更后的网络反应](../static/network_reaction_ospf_cost_change.png)

## 网络热力图 { #network-heatmap }

**网络热力图**（位于 Analytics 分析菜单下）能让您一眼看清拓扑的结构特性——
哪些链路和节点承载的路径最多、单点故障位于何处，以及哪些网络**没有备份路径**。

![带网络的网络热力图](../static/network_heatmap_with_networks.png)

标记为红色的节点承载着最多没有备份路径的网络。

筛选出**没有备份**的网络，精确定位单点故障会导致可达性丢失的位置：

![高亮显示无备份网络的热力图](../static/network_heatmap_with_not_backuped_networks.png)

## 检测非对称路径

去程和回程走不同路径的路由会使防火墙、QoS 和故障排查复杂化。Topolograph 的
**Analytics → Asymmetric paths（分析 → 非对称路径）**报告可以为您找出这些路径对。

![分析菜单——非对称路径](../static/analytics_menu_asym_paths.png)

![一个真实的非对称路径示例](../static/asymmetric_path_real_example.png)

## 接下来可以做什么

<div class="grid cards" markdown>

-   :material-compare:{ .lg .middle } __比较两个快照__

    ---

    查看两次采集之间发生了什么变化。

    [:octicons-arrow-right-24: 比较网络状态](comparing-states.md)

-   :material-tune-variant:{ .lg .middle } __添加 TE 数据__

    ---

    带宽、TE 度量、管理组。

    [:octicons-arrow-right-24: 流量工程](traffic-engineering.md)

-   :material-radar:{ .lg .middle } __实时监控__

    ---

    实时捕获每一次变化。

    [:octicons-arrow-right-24: 实时监控](../monitoring/index.md)

</div>

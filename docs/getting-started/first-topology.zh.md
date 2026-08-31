# 您的第一个拓扑

本教程将带您从一个刚刚运行起来的 Topolograph，使用最简单的输入方式——从一台
路由器复制的**文本文件**——完成您的第一次图分析。

!!! info "您将需要"
    - 一个正在运行的 Topolograph 实例（[使用 Docker 安装](quickstart-docker.md)）。
    - 对您想要映射的 OSPF 或 IS-IS 区域中**一台**路由器的访问权限。

## 1. 从一台设备获取 LSDB

由于整个区域共享同一个数据库，您只需从**单台**路由器采集即可。选择适合您平台的
命令——完整的对照表位于[支持的厂商](../reference/supported-vendors.md)页面。例如：

=== "Cisco (OSPF)"

    ```
    show ip ospf database router
    show ip ospf database network
    show ip ospf database external
    ```

=== "Juniper (OSPF)"

    ```
    show ospf database router extensive | no-more
    show ospf database network extensive | no-more
    show ospf database external extensive | no-more
    ```

=== "FRRouting (OSPF)"

    ```
    show ip ospf database router
    show ip ospf database network
    show ip ospf database external
    ```

=== "Cisco (IS-IS)"

    ```
    show isis database detail
    ```

将输出保存为纯文本文件。您可以把 LSA 1 / 2 / 5 部分粘贴到同一个文件中。

!!! tip "更丰富的链路信息（可选）"
    对于 FRRouting OSPF，将 `show ip ospf database opaque-area` 的输出追加到
    同一个文件中，即可引入带宽、TE 度量和管理组数据。这是可选的——图仍然可以
    仅凭 LSA 1/2/5 构建。参见[流量工程](../analysis/traffic-engineering.md)。

## 2. 上传它

1. 在 `http://localhost:8080/` 打开 Topolograph。
2. 选择上传拓扑，并粘贴（或上传）您的文本文件。
3. 选择与您的采集内容相匹配的**厂商**和**协议**。
4. 提交——Topolograph 会解析 LSDB 并渲染出图。

![上传 LSDB 并获得图](../assets/text_file_and_short_paths.gif)

结果是一个**快照**：捕获数据库那一刻网络状态的一张定格图片。您在这里运行的
每一次分析都是针对这个快照进行的，因此在这里所做的任何操作都不会影响到实际
运行中的网络。

## 3. 构建最短路径

图显示出来后，选择一个源节点和一个目标节点，构建它们之间的最短路径。
Topolograph 会高亮显示该路径并展示其总开销。

![构建最短路径树](../assets/build-spt.gif)

从这里您可以立即：

- 揭示主路径故障时网络会使用的**备份路径**。
- **关闭一条链路或一个节点**，观察流量重新路由。
- 打开**网络热力图**，找出负载最高、保护最薄弱的链路。

以上所有内容都在[分析与可视化](../analysis/index.md)中有详细介绍。

## 4. 接下来去哪里

<div class="grid cards" markdown>

-   :material-transit-connection-variant:{ .lg .middle } __实时流式获取__

    ---

    厌倦了复制粘贴？让 Watcher 通过 GRE 或 BGP-LS 自动提供拓扑数据。

    [:octicons-arrow-right-24: 获取拓扑数据](../ingestion/index.md)

-   :material-vector-polyline:{ .lg .middle } __深入分析__

    ---

    备份路径、ECMP、故障模拟、开销规划，以及热力图。

    [:octicons-arrow-right-24: 分析与可视化](../analysis/index.md)

-   :material-radar:{ .lg .middle } __持续监控__

    ---

    捕获每一次邻接关系和开销变化，并发送到 ELK、Zabbix 或 Slack。

    [:octicons-arrow-right-24: 实时监控](../monitoring/index.md)

-   :material-console:{ .lg .middle } __自动化__

    ---

    使用 `topo` CLI 和 Python SDK 采集并上传 LSDB。

    [:octicons-arrow-right-24: Python SDK](../automation/python-sdk.md)

</div>

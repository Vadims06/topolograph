# 快速入门

刚接触 Topolograph？从这里开始。

<div class="grid cards" markdown>

-   :material-help-circle-outline:{ .lg .middle } __什么是 Topolograph？__

    ---

    了解 Topolograph 的功能、它所解决的问题，以及产品套件各部分是如何协同工作的。

    [:octicons-arrow-right-24: 阅读概述](what-is-topolograph.md)

-   :material-docker:{ .lg .middle } __使用 Docker 快速开始__

    ---

    使用 Docker Compose 在几分钟内启动本地自托管实例。

    [:octicons-arrow-right-24: 使用 Docker 安装](quickstart-docker.md)

-   :material-flag-checkered:{ .lg .middle } __您的第一个拓扑__

    ---

    从一台路由器上传链路状态数据库，构建您的第一条最短路径。

    [:octicons-arrow-right-24: 构建您的第一个图](first-topology.md)

</div>

## 60 秒了解 Topolograph

1. 使用 [Docker](quickstart-docker.md) 在本地**运行 Topolograph**。
2. **导入您的拓扑数据** —— [粘贴 LSDB 文本文件](../ingestion/text-file.md)，
   或通过 [GRE](../ingestion/gre.md) 或 [BGP-LS](../ingestion/bgp-ls.md) 的
   Watcher 会话实时流式获取。
3. **分析拓扑** —— [构建路径、模拟故障、发现薄弱环节](../analysis/index.md)。
4. **监控拓扑** —— 启用 [Watcher](../monitoring/index.md) 以捕获每一次变化并发出告警。

---
title: Topolograph — OSPF 与 IS-IS 拓扑可视化与分析
hide:
  - navigation
  - toc
---

<div class="tg-hero" markdown>
<div class="tg-hero__copy" markdown>

<h1 class="tg-hero__title">以协议的视角查看您的 OSPF 与 IS-IS 网络</h1>

<p class="tg-hero__tagline">
Topolograph 通过单台设备的链路状态数据库（LSDB）构建您的 OSPF/IS-IS 拓扑——然后让您
追踪最短路径和备份路径、模拟链路和节点故障、规划链路开销，并实时监控 IGP 的变化。
自托管、离线运行，无需登录或密码。
</p>

<div class="tg-hero__buttons" markdown>
[开始使用 :material-rocket-launch:](getting-started/quickstart-docker.md){ .md-button .tg-cta }
[什么是 Topolograph？ :material-help-circle-outline:](getting-started/what-is-topolograph.md){ .md-button }
[在 GitHub 上查看 :fontawesome-brands-github:](https://github.com/Vadims06/topolograph){ .md-button }
</div>

</div>
<div class="tg-hero__media" markdown>
![Topolograph — 上传 LSDB 并构建最短路径](assets/text_file_and_short_paths.gif)
</div>
</div>

<div class="tg-vendors" markdown>
<span>Cisco</span> <span>Cisco NX-OS</span> <span>Juniper</span> <span>Nokia</span>
<span>Huawei</span> <span>FRRouting</span> <span>Arista</span> <span>MikroTik</span>
<span>Palo Alto</span> <span>Fortinet</span> <span>Extreme</span> <span>Bird</span>
<span>Ruckus</span> <span>Allied Telesis</span> <span>Ericsson</span> <span>Ubiquiti</span>
</div>

---

## 您可以做什么

<div class="grid cards" markdown>

-   :material-graph-outline:{ .lg .middle } __可视化拓扑__

    ---

    上传 LSDB 文本文件或实时流式传输，获得与路由器所见完全一致的交互式 OSPF/IS-IS 图。

    [:octicons-arrow-right-24: 获取拓扑数据](ingestion/index.md)

-   :material-vector-polyline:{ .lg .middle } __构建路径与备份__

    ---

    计算任意两个节点之间的最短路径，然后展示主路径、备份路径和 ECMP 行为。

    [:octicons-arrow-right-24: 分析与可视化](analysis/visualizing.md)

-   :material-flash-alert:{ .lg .middle } __模拟故障__

    ---

    关闭一条链路或一台路由器，立即查看流量如何重新路由——无需触碰生产网络。

    [:octicons-arrow-right-24: 故障模拟](analysis/visualizing.md#simulating-failures)

-   :material-radar:{ .lg .middle } __实时监控__

    ---

    运行 OSPF Watcher 或 IS-IS Watcher，捕获每一次邻接关系、开销和网络变化，并将事件
    发送到 ELK、Zabbix 或 Slack。

    [:octicons-arrow-right-24: 实时监控](monitoring/index.md)

-   :material-fire:{ .lg .middle } __发现薄弱环节__

    ---

    使用网络热力图和分析功能，找出负载最高的链路、单点故障和缺乏备份的网络。

    [:octicons-arrow-right-24: 网络热力图](analysis/visualizing.md#network-heatmap)

-   :material-robot-happy-outline:{ .lg .middle } __自动化与自然语言查询__

    ---

    通过 Python SDK 和 CLI、REST API、MCP 服务器或自然语言 AI 代理来驱动一切。

    [:octicons-arrow-right-24: 自动化与 API](automation/index.md)

</div>

## 三种导入拓扑数据的方式

<div class="grid cards" markdown>

-   __:material-file-document-outline: 文本文件__

    粘贴或上传单台路由器的 LSDB 输出。非常适合临时分析、审计和离线假设场景规划。

    [:octicons-arrow-right-24: 上传文本文件](ingestion/text-file.md)

-   __:material-tunnel: GRE 会话__

    Watcher 通过 GRE 邻接与路由器建立对等关系，并将实时链路状态变化转发到 Topolograph。

    [:octicons-arrow-right-24: GRE 会话](ingestion/gre.md)

-   __:material-transit-connection-variant: BGP-LS 会话__

    通过 GoBGP 和 Watcher 转发器，原生地在 BGP-LS 上承载 OSPF 或 IS-IS 链路状态——无需
    GRE 隧道。

    [:octicons-arrow-right-24: BGP-LS 会话](ingestion/bgp-ls.md)

</div>

## Topolograph 产品套件

| 组件 | 简介 | 文档 |
| --- | --- | --- |
| **Topolograph** | Web 应用：可视化、分析、模拟、比较 | [分析与可视化](analysis/index.md) |
| **OSPF Watcher** | 实时 OSPF 变化监控（GRE 或 BGP-LS） | [OSPF Watcher](monitoring/ospf-watcher.md) |
| **IS-IS Watcher** | 实时 IS-IS 变化监控（GRE 或 BGP-LS） | [IS-IS Watcher](monitoring/isis-watcher.md) |
| **BMP Watcher** | 实时 BGP 会话、路由与 VPN 上下文（BMP） | [BMP Watcher](monitoring/bmp-watcher.md) |
| **Python SDK** | 面向对象的 API 客户端 + SSH 采集器 + `topo` CLI | [Python SDK](automation/python-sdk.md) |
| **MCP Server** | 面向 LLM 代理的 Model Context Protocol 封装 | [MCP Server](automation/mcp-server.md) |
| **AI Agent** | 面向您的 IGP 的自然语言助手 | [AI Agent](automation/ai-agent.md) |

---

<p style="text-align:center; margin-top:2rem;">
准备好试试了吗？<a href="getting-started/quickstart-docker.md"><strong>几分钟内使用 Docker 启动本地实例 →</strong></a>
</p>

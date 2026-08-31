# MCP Server

**Topolograph MCP Server** 通过 [Model Context Protocol](https://modelcontextprotocol.io/)
将 Topolograph API 暴露出来，因此 LLM 代理（Claude 及其他）可以用自然语言
实时查询拓扑、监控事件并计算路径——无需定制的 API 胶水代码。

[:simple-github: vadims06/topolograph-mcp-server](https://github.com/Vadims06/topolograph-mcp-server){ .md-button }

## 运行方式

MCP server **已捆绑在
[topolograph-docker](https://github.com/Vadims06/topolograph-docker)** 中——
这是将其作为完整技术栈一部分运行的最简单方式：

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
```

它会在 `http://localhost:8000/mcp` 上启动，并自动连接到 Topolograph API。

### 独立运行

```bash
pip install -r requirements.txt
export TOPOLOGRAPH_API_BASE="https://your-topolograph-api-url"
export TOPOLOGRAPH_API_TOKEN="your-api-token"   # optional
python mcp-server.py
```

默认端点：`http://0.0.0.0:8000/mcp`。

## 可用工具

| 工具 | 用途 |
| --- | --- |
| `get_all_graphs` | 列出可用的图，支持筛选 |
| `get_graph_by_time` | 按时间获取特定的图 |
| `get_network_by_graph_time` | 查询网络信息（按 IP、节点 ID 或掩码） |
| `get_graph_status` | 检查图的健康状况和连通性 |
| `get_network_events` | 获取网络 up/down 事件 |
| `get_adjacency_events` | 获取节点/主机和链路事件 |
| `get_nodes` | 查询图上的节点 |
| `get_edges` | 查询图上的链路 |
| `get_shortest_path` | 计算最短路径（支持备份路径） |
| `upload_graph` | 上传一个新的图 |

## 它能带来什么

将这些工具接入一个代理后，您就可以提出诸如*"现在哪些图是连通的？"*、
*"这两个 IP 之间的路由是什么？"*，或*"上一次拓扑事件之后发生了什么变化？"*
这样的问题，并获得基于您真实 IGP 的答案——这正是 [AI Agent](ai-agent.md)
所构建的基础。

---

**相关内容：** [AI Agent](ai-agent.md) · [Python SDK](python-sdk.md) ·
[使用 Docker 快速开始](../getting-started/quickstart-docker.md)

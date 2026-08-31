# 自动化与 API

您在 Topolograph 界面中能做的一切，都可以通过编程方式完成。选择适合您工作流程的接口：

<div class="grid cards" markdown>

-   :material-language-python:{ .lg .middle } __Python SDK__

    ---

    面向对象的 REST 客户端、基于 SSH 的 LSDB 采集器（Nornir），以及 `topo` CLI。

    [:octicons-arrow-right-24: Python SDK](python-sdk.md)

-   :material-server-network:{ .lg .middle } __MCP Server__

    ---

    通过 Model Context Protocol，将 Topolograph API 暴露给 LLM 代理。

    [:octicons-arrow-right-24: MCP Server](mcp-server.md)

-   :material-robot-happy-outline:{ .lg .middle } __AI Agent__

    ---

    一个自然语言助手，可以回答有关您实时 IGP 的问题。

    [:octicons-arrow-right-24: AI Agent](ai-agent.md)

</div>

## 底层的 REST API

以上所有功能都构建在 Topolograph 的 REST API 之上。完整的交互式模式（schema）位于您实例上的
**`/api/ui/`**（对于托管服务，参见
[topolograph.com/api/ui](https://topolograph.com/api/ui/)）。

直接上传就是这么简单：

```python
import requests

r = requests.post(
    'https://topolograph.com/api/graph',
    auth=('youraccount@domain.com', 'your-pass'),
    json={'ospf_data': '<your LSDB text>'},
)
```

如果不只是一次性调用，[Python SDK](python-sdk.md) 为相同的端点提供了更加友好的接口。

!!! tip "为 LLM 而设计"
    Topolograph 的数据模型可以清晰地映射到自然语言问题，这正是 [MCP Server](mcp-server.md) 和
    [AI Agent](ai-agent.md) 存在的原因——直接问“这两个 IP 之间的路径是什么？”，而不必编写 API 调用。

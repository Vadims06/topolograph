# Automation & APIs

Everything you can do in the Topolograph UI, you can do programmatically. Pick
the surface that fits your workflow:

<div class="grid cards" markdown>

-   :material-language-python:{ .lg .middle } __Python SDK__

    ---

    Object-oriented REST client, an SSH-based LSDB collector (Nornir), and the
    `topo` CLI.

    [:octicons-arrow-right-24: Python SDK](python-sdk.md)

-   :material-server-network:{ .lg .middle } __MCP Server__

    ---

    Expose the Topolograph API to LLM agents over the Model Context Protocol.

    [:octicons-arrow-right-24: MCP Server](mcp-server.md)

-   :material-robot-happy-outline:{ .lg .middle } __AI Agent__

    ---

    A natural-language assistant that answers questions about your live IGP.

    [:octicons-arrow-right-24: AI Agent](ai-agent.md)

</div>

## The REST API underneath

All of these are built on Topolograph's REST API. The full, interactive schema
lives at **`/api/ui/`** on your instance (for the hosted service,
[topolograph.com/api/ui](https://topolograph.com/api/ui/)).

A direct upload is as simple as:

```python
import requests

r = requests.post(
    'https://topolograph.com/api/graph',
    auth=('youraccount@domain.com', 'your-pass'),
    json={'ospf_data': '<your LSDB text>'},
)
```

For anything beyond a one-off call, the [Python SDK](python-sdk.md) gives you a
much friendlier interface over the same endpoints.

!!! tip "LLM-friendly by design"
    Topolograph's data model maps cleanly onto natural-language questions, which
    is why the [MCP server](mcp-server.md) and [AI agent](ai-agent.md) exist —
    ask "what's the path between these two IPs?" instead of crafting an API call.

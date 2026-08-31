# MCP Server

The **Topolograph MCP Server** exposes the Topolograph API through the
[Model Context Protocol](https://modelcontextprotocol.io/), so LLM agents (Claude,
and others) can query topologies, monitor events, and compute paths in real time —
in natural language, without bespoke API glue.

[:simple-github: vadims06/topolograph-mcp-server](https://github.com/Vadims06/topolograph-mcp-server){ .md-button }

## Run it

The MCP server is **bundled in
[topolograph-docker](https://github.com/Vadims06/topolograph-docker)** — the
easiest way to run it as part of the full stack:

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
```

It comes up at `http://localhost:8000/mcp` and connects to the Topolograph API
automatically.

### Standalone

```bash
pip install -r requirements.txt
export TOPOLOGRAPH_API_BASE="https://your-topolograph-api-url"
export TOPOLOGRAPH_API_TOKEN="your-api-token"   # optional
python mcp-server.py
```

Default endpoint: `http://0.0.0.0:8000/mcp`.

## Available tools

| Tool | Purpose |
| --- | --- |
| `get_all_graphs` | List available graphs with filtering |
| `get_graph_by_time` | Fetch a specific graph by time |
| `get_network_by_graph_time` | Query network info (by IP, node ID, or mask) |
| `get_graph_status` | Check graph health and connectivity |
| `get_network_events` | Retrieve network up/down events |
| `get_adjacency_events` | Get node/host and link events |
| `get_events_timeline` | Merged timeline of network and adjacency events |
| `get_nodes` | Query diagram nodes |
| `get_edges` | Query diagram edges |
| `get_shortest_path` | Compute shortest paths (with backup-path support) |
| `get_cspf_path` | Constraint-filtered (CSPF) path, without creating a tunnel |
| `get_edge_failure_reaction` | Predict the whole-network impact of links failing |
| `get_lsps` | List MPLS TE LSP tunnels and their CSPF placement result |
| `add_lsp` | Add an MPLS TE LSP tunnel to a graph |
| `update_lsp` | Update or rename an MPLS TE LSP tunnel |
| `delete_lsp` | Delete one LSP tunnel, or all tunnels on the graph |
| `upload_graph` | Upload a new graph |

## What it unlocks

With these tools wired into an agent, you can ask questions like *"which graphs
are connected right now?"*, *"what's the route between these two IPs?"*, or *"what
changed after the last topology event?"* and get answers grounded in your real
IGP — which is exactly what the [AI Agent](ai-agent.md) is built on.

---

**Related:** [AI Agent](ai-agent.md) · [Python SDK](python-sdk.md) ·
[Quick Start with Docker](../getting-started/quickstart-docker.md)

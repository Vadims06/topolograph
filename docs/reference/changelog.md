# Changelog

A high-level tour of notable milestones. For the complete, version-by-version
notes, see the GitHub releases for each component.

[:material-tag-multiple: Topolograph releases](https://github.com/Vadims06/topolograph/releases){ .md-button }

## Milestones

| Milestone | What landed |
| --- | --- |
| **Topolograph v2.27** | OSPF Watcher topology changes can be shown on the network graph (compatible with `ospfwatcher v1.1`). |
| **Topolograph v2.32** | **YAML-based topologies** — build arbitrary graphs from YAML and keep them updated via REST API (Network Diagram as a Service). See [YAML topologies](../analysis/yaml-topologies.md). |
| **Topolograph v2.34** | Multi-device LSDB upload via the REST API. |
| **Topolograph v2.38** | IS-IS Watcher topology changes can be shown on the graph (compatible with `isiswatcher v1.0`). |
| **ospf-watcher v3.1.0** | **BGP-LS ingestion** for OSPF (GoBGP + forwarder). The IS-IS Watcher gains the equivalent. See [BGP-LS](../ingestion/bgp-ls.md). |
| **Topolograph v3.x** | Watcher **heartbeats** — the UI lists registered Watchers with `up` / `stale` / `down` liveness. |

!!! note "Compatibility pairing"
    Watcher features that render on the Topolograph graph depend on a minimum
    Topolograph version (e.g. OSPF → v2.27, IS-IS → v2.38). Keep Topolograph and
    your Watchers reasonably aligned.

## Per-component release notes

| Component | Releases |
| --- | --- |
| Topolograph | <https://github.com/Vadims06/topolograph/releases> |
| OSPF Watcher | <https://github.com/Vadims06/ospfwatcher/releases> |
| IS-IS Watcher | <https://github.com/Vadims06/isiswatcher/releases> |
| Python SDK | <https://pypi.org/project/topolograph-sdk/> |
| MCP Server | <https://github.com/Vadims06/topolograph-mcp-server/releases> |

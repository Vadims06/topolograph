# Deployment & Configuration

This page collects the deployment knobs for a self-hosted Topolograph. For a
step-by-step first run, see
[Quick Start with Docker](../getting-started/quickstart-docker.md).

## Install

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d

!!! info "No third-party analytics"
    The Docker image does not load the Google Analytics and Yandex Metrika counters that topolograph.com uses.
# or: sudo ./install.sh   (can also bring up the Watchers)
```

Open `http://localhost:8080/`.

## Environment variables

Configuration lives in `.env` next to `docker-compose.yml`.

| Variable | Purpose |
| --- | --- |
| `TOPOLOGRAPH_PORT` | Web UI port (default `8080`). |
| `MCP_PORT` | [MCP server](../automation/mcp-server.md) port (default `8000`). |
| `DNS` | DNS server IP used to resolve router IDs into device names. |
| `DNS_LOOKUP_DEADLINE_SEC` | Max seconds an upload waits for DNS names (default `5`). Nodes not resolved in time keep their IP as a label. |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL`, `TOPOLOGRAPH_WEB_API_PASSWORD` | REST API credentials. |
| `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS` | Allow-list of source IP ranges for API calls. |
| `TOPOLOGRAPH_API_TOKEN` | Token to authenticate REST API requests instead of a username/password pair. |

After changing any value, re-apply with `docker-compose up -d`.

### Watcher-side variables

When you also run a [Watcher](../monitoring/index.md), its `.env` adds a few more:

| Variable | Purpose |
| --- | --- |
| `TOPOLOGRAPH_HOST` | IP of the host running Topolograph. **Don't use `localhost`** — the Watcher, ELK and Topolograph each run in their own network space. |
| `TOPOLOGRAPH_PORT` | Topolograph port (default `8080`). |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `_PASSWORD` | API user the Watcher posts as (e.g. `ospf@topolograph.com`). |
| `TEST_MODE` | If `True`, replays demo events from a static file instead of reading the live IGP. |
| `WATCHER_IP` | Override the Watcher's reported source IP (`srcid`) when hostname resolution is unreliable in containers. |
| `EXPORT_TO_ELASTICSEARCH_BOOL`, `ELASTIC_IP` | Enable and target an [ELK](../monitoring/elk-kibana.md) stack. |
| `EXPORT_TO_WEBHOOK_URL_BOOL`, `WEBHOOK_URL` | Enable [WebHook/Slack](../monitoring/webhooks.md) notifications. |

## Create default credentials

Run once to create the API user from your `.env` and load the allowed networks:

```python
import requests
print(requests.post('http://localhost:8080/create-default-credentials').json())
# {'errors': '', 'status': 'ok'}
```

Verify: log in at `http://localhost:8080/` via **Login → Local login**, then check
**API → Authorised source IP ranges**.

## What's in the stack

The `topolograph-docker` compose can run, in any combination:

- **Topolograph** web app + database
- **MCP server** (`/mcp` on `MCP_PORT`)
- **OSPF / IS-IS Watchers**
- **ELK** stack for event search

## Hosted alternative

A hosted instance is available at [topolograph.com](https://topolograph.com). Pick
self-hosting when your LSDB data must stay inside your environment.

---

**Related:** [Quick Start](../getting-started/quickstart-docker.md) ·
[Real-time monitoring](../monitoring/index.md)

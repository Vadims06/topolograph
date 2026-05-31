# Quick Start with Docker

The fastest way to run Topolograph is the self-hosted Docker image. It bundles
the web app, its database, and (optionally) the MCP server and Watchers.

!!! tip "Prerequisites"
    Install **Docker** and **Docker Compose**. On Windows/macOS, Docker Desktop
    includes both.

## 1. Clone and start

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
```

Prefer a one-shot installer that can also bring up the Watchers? Use the
`install.sh` script instead:

```bash
sudo ./install.sh
```

…or run it straight from GitHub:

```bash
curl -O https://raw.githubusercontent.com/Vadims06/topolograph-docker/master/install.sh
chmod +x install.sh
sudo ./install.sh
```

Give it a minute or two to come up, then open:

```
http://localhost:8080/
```

## 2. Configure with `.env`

Configuration lives in a `.env` file next to `docker-compose.yml`. The most
useful variables:

| Variable | Purpose |
| --- | --- |
| `TOPOLOGRAPH_PORT` | Web UI port (default `8080`). Open `http://localhost:<port>/` after restarting. |
| `NAPALM_USERNAME`, `NAPALM_PASSWORD` | Credentials Topolograph uses to log in to a device and pull its OSPF LSDB via NAPALM. |
| `DNS` | IP of a DNS server, used to resolve router IDs into device names on the graph. |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL`, `TOPOLOGRAPH_WEB_API_PASSWORD` | Credentials for REST API requests. |
| `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS` | Allow-list of source IP ranges permitted to call the API. |
| `MCP_PORT` | Port for the bundled [MCP server](../automation/mcp-server.md) (default `8000`). |

After changing a port or other value, re-apply it:

```bash
docker-compose up -d
```

## 3. Create the default credentials

To create the API user from your `.env` values and load your allowed networks
into the allow-list, send this request once:

```python
import requests
res = requests.post('http://localhost:8080/create-default-credentials')
print(res.json())
# {'errors': '', 'status': 'ok'}
```

Verify it worked:

1. Open `http://localhost:8080/` in a browser.
2. Go to **Login → Local login** and sign in with
   `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `TOPOLOGRAPH_WEB_API_PASSWORD`.
3. The **API → Authorised source IP ranges** tab should list the ranges from
   `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS`.

## What's included

The `docker-compose.yml` in `topolograph-docker` can run more than just the web
app:

- **Topolograph** web application + database.
- **MCP server** at `http://localhost:8000/mcp` for
  [LLM/agent access](../automation/mcp-server.md).
- Optional **OSPF/IS-IS Watchers** and an **ELK** stack for
  [real-time monitoring](../monitoring/index.md).

!!! note "Hosted option"
    Don't want to self-host? A hosted instance is available at
    [topolograph.com](https://topolograph.com). The Docker version is ideal when
    your LSDBs shouldn't leave your environment.

---

**Next:** [Build your first topology →](first-topology.md)

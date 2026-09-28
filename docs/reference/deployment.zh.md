# 部署与配置

本页汇总了自托管 Topolograph 的各项部署配置。想要循序渐进的初次运行指南，
请参见[使用 Docker 快速开始](../getting-started/quickstart-docker.md)。

## 安装

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d

!!! info "不含第三方统计"
    Docker 镜像不会加载 topolograph.com 使用的 Google Analytics 和 Yandex Metrika 计数器。
# or: sudo ./install.sh   (can also bring up the Watchers)
```

打开 `http://localhost:8080/`。

## 环境变量

配置存放在 `docker-compose.yml` 旁边的 `.env` 中。

| 变量 | 用途 |
| --- | --- |
| `TOPOLOGRAPH_PORT` | Web UI 端口（默认 `8080`）。 |
| `MCP_PORT` | [MCP server](../automation/mcp-server.md) 端口（默认 `8000`）。 |
| `DNS` | 用于将路由器 ID 解析为设备名称的 DNS 服务器 IP。 |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL`、`TOPOLOGRAPH_WEB_API_PASSWORD` | REST API 凭据。 |
| `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS` | 允许调用 API 的源 IP 范围白名单。 |
| `TOPOLOGRAPH_API_TOKEN` | 用于对 REST API 请求进行身份验证的令牌，可替代用户名/密码。 |

更改任何值之后，使用 `docker-compose up -d` 重新应用。

### Watcher 端变量

当您同时运行一个 [Watcher](../monitoring/index.md) 时，它的 `.env` 会
添加几个额外的变量：

| 变量 | 用途 |
| --- | --- |
| `TOPOLOGRAPH_HOST` | 运行 Topolograph 的主机的 IP。**不要使用 `localhost`**——Watcher、ELK 和 Topolograph 各自运行在自己的网络空间中。 |
| `TOPOLOGRAPH_PORT` | Topolograph 端口（默认 `8080`）。 |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `_PASSWORD` | Watcher 用于提交数据的 API 用户（例如 `ospf@topolograph.com`）。 |
| `TEST_MODE` | 如果为 `True`，则从静态文件回放演示事件，而不是读取实时 IGP。 |
| `WATCHER_IP` | 在容器中主机名解析不可靠时，覆盖 Watcher 上报的源 IP。 |
| `EXPORT_TO_ELASTICSEARCH_BOOL`、`ELASTIC_IP` | 启用并指向一个 [ELK](../monitoring/elk-kibana.md) 技术栈。 |
| `EXPORT_TO_WEBHOOK_URL_BOOL`、`WEBHOOK_URL` | 启用 [WebHook/Slack](../monitoring/webhooks.md) 通知。 |

## 创建默认凭据

运行一次，即可根据您的 `.env` 创建 API 用户并加载允许的网络：

```python
import requests
print(requests.post('http://localhost:8080/create-default-credentials').json())
# {'errors': '', 'status': 'ok'}
```

验证：通过 **Login → Local login** 在 `http://localhost:8080/` 登录，然后
检查 **API → Authorised source IP ranges**。

## 技术栈包含哪些内容

`topolograph-docker` 的 compose 可以任意组合运行以下内容：

- **Topolograph** Web 应用 + 数据库
- **MCP server**（`MCP_PORT` 上的 `/mcp`）
- **OSPF / IS-IS Watcher**
- 用于事件搜索的 **ELK** 技术栈

## 托管替代方案

可以在 [topolograph.com](https://topolograph.com) 上使用托管实例。当您的
LSDB 数据必须留在您自己的环境内时，请选择自托管。

---

**相关内容：** [快速开始](../getting-started/quickstart-docker.md) ·
[实时监控](../monitoring/index.md)

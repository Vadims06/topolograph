# 使用 Docker 快速开始

运行 Topolograph 最快的方式是使用自托管的 Docker 镜像。它打包了 Web 应用、
数据库，以及（可选的）MCP server 和 Watcher。

!!! tip "前置条件"
    安装 **Docker** 和 **Docker Compose**。在 Windows/macOS 上，Docker Desktop
    已经包含了这两者。

## 1. 克隆并启动

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
```

更喜欢一键式安装脚本、还能一并启动 Watcher？改用 `install.sh` 脚本：

```bash
sudo ./install.sh
```

……或者直接从 GitHub 运行它：

```bash
curl -O https://raw.githubusercontent.com/Vadims06/topolograph-docker/master/install.sh
chmod +x install.sh
sudo ./install.sh
```

给它一两分钟时间启动，然后打开：

```
http://localhost:8080/
```

## 2. 使用 `.env` 进行配置

配置存放在 `docker-compose.yml` 旁边的 `.env` 文件中。最常用的变量：

| 变量 | 用途 |
| --- | --- |
| `TOPOLOGRAPH_PORT` | Web UI 端口（默认 `8080`）。重启后打开 `http://localhost:<port>/`。 |
| `DNS` | DNS 服务器的 IP，用于在图上将路由器 ID 解析为设备名称。 |
| `DNS_LOOKUP_DEADLINE_SEC` | 上传时等待 DNS 名称的最长秒数（默认 `5`）。未及时解析的节点仍以 IP 作为标签。 |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL`、`TOPOLOGRAPH_WEB_API_PASSWORD` | 用于 REST API 请求的凭据。 |
| `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS` | 允许调用 API 的源 IP 范围白名单。 |
| `TOPOLOGRAPH_API_TOKEN` | 用于对 REST API 请求进行身份验证的令牌，可替代用户名/密码。 |
| `MCP_PORT` | 内置 [MCP server](../automation/mcp-server.md) 使用的端口（默认 `8000`）。 |

更改端口或其他值之后，重新应用它：

```bash
docker-compose up -d
```

## 3. 创建默认凭据

要根据您的 `.env` 值创建 API 用户，并将您允许的网络加载到白名单中，请发送一次
以下请求：

```python
import requests
res = requests.post('http://localhost:8080/create-default-credentials')
print(res.json())
# {'errors': '', 'status': 'ok'}
```

验证是否生效：

1. 在浏览器中打开 `http://localhost:8080/`。
2. 前往 **Login → Local login**，使用
   `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `TOPOLOGRAPH_WEB_API_PASSWORD` 登录。
3. **API → Authorised source IP ranges** 标签页应列出来自
   `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS` 的范围。

## 包含哪些内容

`topolograph-docker` 中的 `docker-compose.yml` 可以运行的不只是 Web 应用：

- **Topolograph** Web 应用程序 + 数据库。
- 位于 `http://localhost:8000/mcp` 的 **MCP server**，用于
  [LLM/代理访问](../automation/mcp-server.md)。
- 可选的 **OSPF/IS-IS Watcher** 与 **ELK** 技术栈，用于
  [实时监控](../monitoring/index.md)。

!!! note "托管选项"
    不想自托管？可以使用 [topolograph.com](https://topolograph.com) 上的托管实例。
    当您的 LSDB 不应离开您的环境时，Docker 版本是理想选择。

---

**下一步：** [构建您的第一个拓扑 →](first-topology.md)

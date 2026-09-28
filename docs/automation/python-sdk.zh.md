# Python SDK

**Topolograph Python SDK** 是一个 Pythonic、面向对象的 REST API 客户端——此外还内置了从设备采集
LSDB 的 **SSH 采集器**，以及基于其构建的 `topo` **CLI**。

[:simple-pypi: PyPI 上的 topolograph-sdk](https://pypi.org/project/topolograph-sdk/){ .md-button }
[:simple-github: vadims06/topolograph-sdk](https://github.com/Vadims06/topolograph-sdk){ .md-button }

## 安装

```bash
pip install topolograph-sdk
```

## 连接

```python
from topolograph import Topolograph

topo = Topolograph(
    url="http://localhost:8080",
    token="your-api-token",   # or set TOPOLOGRAPH_TOKEN
)

graph = topo.graphs.get(latest=True)
print(graph.graph_time, graph.protocols, graph.hosts['count'])
print(graph.status()['status'])
```

!!! info "身份验证（按优先级排序）"
    1. **Token** 参数——`Topolograph(url=..., token=...)`
    2. **环境变量**——`export TOPOLOGRAPH_TOKEN=...`
    3. **Basic auth**——`Topolograph(url=..., username=..., password=...)`

## 通过 SSH 采集拓扑数据

该 SDK 可以登录到您的设备，运行相应厂商的 LSDB 命令，并将原始输出返回给您——随时可以上传。各厂商的具体命令列在[支持的厂商](../reference/supported-vendors.md)页面。

```python
from topolograph import TopologyCollector

collector = TopologyCollector("inventory.yaml")
result = collector.collect()

graph = topo.uploader.upload_raw(
    lsdb_text=result.raw_lsdb_text,
    vendor="FRR",
    protocol="isis",
)
```

### 清单文件格式

```yaml
router1:
  hostname: 172.20.20.2
  username: admin
  password: admin
  vendor: frr
  protocol: isis
  port: 22

router2:
  hostname: 172.20.20.3
  username: admin
  password: admin
  vendor: cisco
  protocol: ospf
```

每台主机必须包含：`hostname`、`username`、`password`、`vendor`（`cisco`、`juniper`、`frr`、
`arista`、`nokia`、`huawei`），以及 `protocol`（`ospf` / `isis`）。`port` 是可选项（默认为
22）。项目中附带了一个示例文件 `inventory.yaml.example`。

## 处理图

```python
graphs = topo.graphs.list(protocol="ospf")
graph = topo.graphs.get_by_time("2024-01-15T10:30:00Z")

for node in graph.nodes.get():
    print(node.name, node.id)

graph.networks.find_by_ip("10.10.10.1")
graph.networks.find_by_node("1.1.1.1")
graph.networks.find_by_network("10.10.10.0/24")
```

## 计算路径

```python
# Shortest path between nodes
path = graph.paths.shortest("1.1.1.1", "2.2.2.2")
print(path.cost)
for hops in path.paths:
    print(" -> ".join(hops))

# Between IPs/networks
graph.paths.shortest_network("192.168.1.1", "192.168.2.1")

# Backup path (remove an edge and recompute)
graph.paths.shortest("1.1.1.1", "2.2.2.2",
                     removed_edges=[("1.1.1.1", "3.3.3.3")])
```

## 读取事件

```python
net = graph.events.get_network_events(last_minutes=60)
for e in net['network_up_down_events']:
    print(e.event_object, e.event_status)

adj = graph.events.get_adjacency_events(
    start_time="2024-01-15T10:00:00Z",
    end_time="2024-01-15T11:00:00Z",
)
```

## 按 TE 属性过滤链路

```python
graph.edges_list(temetric__gte=100)
graph.edges_list(unreserved_bw_0__lt=1e9)
graph.edges_list(src_node="1.1.1.1", dst_node="2.2.2.2", max_link_bw__gt=1e10)
```

属性列表和操作符请参阅 [流量工程](../analysis/traffic-engineering.md)。

## MPLS TE 隧道

读取图上已声明隧道的 CSPF 放置结果：

```python
graph.lsps_list()                                    # every tunnel path
graph.lsps_list(status="unplaced")                   # only what failed to place
graph.lsps_list(via_node="10.10.10.2")               # paths crossing a node
graph.lsps_list(via_edge="10.10.10.1,10.10.10.2")    # paths crossing a link
graph.lsps_list(include_path=True)                   # add the expanded node path

graph.lsp("TUN_R1_R3")                               # one tunnel, path always included
```

每条路径都带有 `placed`、`cost`，以及——当放置失败时——`reason`、`reason_code` 和
`binding_constraints`。`reason_code` 区分了两类需要不同修复方式的失败：`disconnected`
表示即使解除所有约束也不存在路径（需要修复拓扑），而 `constraints_unsatisfiable` 表示路径存在，
但请求过于严格——需要放宽 `binding_constraints` 中列出的约束（`bandwidth`、`affinity`、
`srlg`）。如果列出了多个约束条目，说明它们只有组合在一起时才会造成阻塞。

使用 `via_edge_key` 而不是 `via_edge`，可以精确锁定并行/ECMP 链路中的某一条；该键值可通过
`graph.edges_list(include=["edge_key"])` 获取。

管理隧道：

```python
graph.add_lsp({"name": "TUN_R1_R3", "src": "10.10.10.1", "dst": "10.10.10.3",
               "bandwidth": "2G"})
graph.update_lsp("TUN_R1_R3", bandwidth="5G")
graph.delete_lsp("TUN_R1_R3")
graph.delete_lsps()                                  # all tunnels on the graph
```

检查是否存在满足约束条件的路径，而无需创建隧道——该检查会考虑已放置隧道占用的带宽：

```python
graph.cspf_path("10.10.10.1", "10.10.10.7",
                bandwidth="5G",
                metric_type="te",
                admin_exclude_any=["red"],
                srlg_exclude=[1001],
                setup_priority=0)
# {'path': [...], 'cost': 42, 'reason': ''}
```

普通的最短路径会忽略隧道，就像未启用 autoroute 时真实的 IP 转发一样。传入 `with_lsps=True`
可以让路径通过 `autoroute` 隧道进行路由：

```python
graph.paths.shortest("10.10.10.1", "10.10.10.4", with_lsps=True)
```

在计入所有已放置隧道之后，某条链路还剩余多少 TE 带宽：

```python
graph.edges_list(include=["lsp_left_bw"])
```

YAML 键参考和 CSPF 放置规则请参阅 [MPLS TE 隧道](../analysis/mpls-te-tunnels.md)。

## `topo` CLI

该 SDK 会安装一个 `topo` 命令：

```bash
# Graphs
topo graphs --list
topo graphs --latest
topo graphs --list --protocol ospf --watcher production-watcher

# Collect & upload
topo ingest inventory.yaml --protocol isis
topo ingest inventory.yaml --output lsdb.txt
topo ingest inventory.yaml --upload --url http://localhost:8080

# Paths
topo path --src 1.1.1.1 --dst 2.2.2.2
topo path --src 192.168.1.1 --dst 192.168.2.1 --network
topo path --src 1.1.1.1 --dst 2.2.2.2 --graph-time "2024-01-15T10:30:00Z"

# Upload an existing LSDB file
topo upload --file lsdb.txt --vendor FRR --protocol isis
topo upload --file lsdb.txt --vendor Cisco --protocol ospf --watcher prod-watcher
```

## 错误处理

```python
from topolograph.exceptions import (
    AuthenticationError, NotFoundError, ValidationError, APIError,
)

try:
    graph = topo.graphs.get_by_time("invalid-time")
except NotFoundError:
    ...
except AuthenticationError:
    ...
except APIError as e:
    print(f"API error: {e}")
```

---

**相关内容：** [获取拓扑数据](../ingestion/index.md) ·
[MCP Server](mcp-server.md)

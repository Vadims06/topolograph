# 基于 YAML 的拓扑

Topolograph 通常从 OSPF/IS-IS LSDB 构建图——但从 **v2.32** 开始，它也可以从
**YAML 定义**构建图。这意味着您可以从零开始设计任意拓扑（它甚至不必是一个 IGP
域），通过 REST API 持续更新它，并对其运行所有相同的分析。

!!! abstract "网络拓扑图即服务"
    LSDB 与 YAML **双向**可互换。您可以从零设计一个 IGP 域，*也可以*将已上传的
    LSDB 导出为 YAML，然后添加链路、更改开销，并重新检查网络对您所做编辑的反应。

## 基础拓扑图

一个 YAML 拓扑图只需要 `nodes` 和 `edges`：

```yaml
nodes:
  10.10.10.1:
    label: Router1
  10.10.10.2:
    label: Router2
edges:
  - src: 10.10.10.1
    dst: 10.10.10.2
    cost: 10
```

通过 REST API 上传：

```python
import requests

yaml_diagram = """
nodes:
  10.10.10.1:
    label: Router1
  10.10.10.2:
    label: Router2
edges:
  - src: 10.10.10.1
    dst: 10.10.10.2
    cost: 10
"""

requests.post(
    'http://<topolograph-host>/api/diagram',
    auth=('', ''),
    json={'yaml_diagram_str': yaml_diagram},
)
```

……或使用 [Python SDK](../automation/python-sdk.md)：

```python
from topolograph import Topolograph

topo = Topolograph(url="topolograph-url", token="your-token")
graph = topo.graphs.upload_diagram(yaml_diagram)
print(f"Diagram uploaded: {graph.graph_time}")
```

## 节点属性与标签

- **节点名称是必填的**，且必须为 IP 地址格式。若要显示更友好的名称，可设置 `label`。
- **标签是可选的。**可以附加任意 `key: value` 键值对（值可以是字符串、数字、
  字典或列表）——例如 `location`、`ha_role`，或任何对您有意义的信息。

标签让节点变得**可查询**。假设有一个 6 节点的图，您可以选择，例如 DC1 中所有的
primary 节点：

```python
query_params = {'location': 'dc1', 'ha_role': 'primary'}
r = requests.get(
    f'http://{HOST}:{PORT}/api/diagram/{graph_time}/nodes',
    auth=('', ''),
    params=query_params,
)
# -> [{'ha_role': 'primary', 'id': 1, 'label': '10.10.10.2',
#      'location': 'dc1', 'name': '10.10.10.2', 'size': 15}]
```

## 链路属性

每条链路至少包含 `src`、`dst` 和 `cost`。链路还可以携带
[流量工程属性](traffic-engineering.md)（带宽、TE 度量、管理组），随后您可以
通过拓扑图链路 API 对这些属性进行筛选。

## 网络属性

终结在某个节点上的子网位于顶层的 `stub_networks:` 部分。它们是终结元数据，
与从真实 LSDB 解析子网时完全相同——不会为它们创建图节点，因此它们计入备份覆盖率
和网络评分，而不计入节点数量。由两个或更多节点通告的子网被视为已备份。

```yaml
stub_networks:
  192.168.1.0/24:
    - node: 10.10.10.1
      cost: 10
      area: 0
    - node: 10.10.10.2
      cost: 20
      area: 0
```

| 键 | 值 / 格式 | 含义 |
|---|---|---|
| subnet | CIDR，例如 `192.168.1.0/24` | 每个条目的键；其值是通告节点的列表 |
| `node` | 节点名称，必须存在于 `nodes` 中 | 通告该子网的节点 |
| `cost` | int | 该节点到子网的开销 |
| `area` | int | 该子网通告所在的区域 |
| `metric_type` | int | IS-IS 度量方式 |
| `isnarrow`、`isextended` | bool | IS-IS 度量编码方式 |

将拓扑导出回 YAML 时会保留此部分，因此 LSDB → YAML → LSDB 的往返转换不会丢失
子网信息。

## MPLS TE 隧道

拓扑图还可以在顶层的 `lsps:` 部分（与 `nodes`/`edges` 并列）声明 RSVP-TE/SR-TE
隧道。Topolograph 会对它们运行 CSPF 放置计算（带宽、affinity、SRLG），并让您
查询结果，或者在不改动图的情况下检查一个假设的新隧道是否能够放置成功。

```yaml
lsps:
  TUN_R1_R3:
    src: 10.10.10.1
    dst: 10.10.10.3
    bandwidth: 2G
```

[:octicons-arrow-right-24: MPLS TE 隧道](mpls-te-tunnels.md)

## 为什么使用它

- **在建设之前验证假设**——规划一条新链路或 LSP，在 YAML 拓扑图中建模，并检查
  网络如何重新收敛。
- **提供网络拓扑图**——从节点和链路构建图，包括元数据，例如提供商、提供商角色
  或节点角色。这就是 Network Diagram as a Service。

---

**下一步：**[流量工程属性 →](traffic-engineering.md)

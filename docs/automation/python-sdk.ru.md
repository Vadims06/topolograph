# Python SDK

**Python SDK Topolograph** - это клиент REST API Topolograph на Python, а
также встроенный **SSH-коллектор**, который собирает LSDB с ваших устройств,
и **CLI** `topo`, построенный поверх него.

[:simple-pypi: topolograph-sdk на PyPI](https://pypi.org/project/topolograph-sdk/){ .md-button }
[:simple-github: vadims06/topolograph-sdk](https://github.com/Vadims06/topolograph-sdk){ .md-button }

## Установка

```bash
pip install topolograph-sdk
```

## Подключение

```python
from topolograph import Topolograph

topo = Topolograph(
    url="http://localhost:8080",
    token="your-api-token",   # or set TOPOLOGRAPH_TOKEN
)

graph = topo.graphs.get(latest=True)
print(graph.graph_time, graph.protocol, graph.hosts['count'])
print(graph.status()['status'])
```

!!! info "Аутентификация (в порядке приоритета)"
    1. Параметр **token** - `Topolograph(url=..., token=...)`
    2. **Переменная окружения** - `export TOPOLOGRAPH_TOKEN=...`
    3. **Basic auth** - `Topolograph(url=..., username=..., password=...)`

## Сбор топологии по SSH

SDK может подключаться к вашим устройствам, выполнять нужные для каждого
вендора команды получения LSDB и отдавать вам сырой вывод - готовый к
загрузке. Точные команды по каждому вендору перечислены на странице
[Поддерживаемые производители](../reference/supported-vendors.md).

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

### Формат инвентаря

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

Обязательные поля для каждого хоста: `hostname`, `username`, `password`,
`vendor` (`cisco`, `juniper`, `frr`, `arista`, `nokia`, `huawei`) и
`protocol` (`ospf` / `isis`). `port` необязателен (по умолчанию 22).
Стартовый файл `inventory.yaml.example` поставляется вместе с проектом.

## Работа с графами

```python
graphs = topo.graphs.list(protocol="ospf")
graph = topo.graphs.get_by_time("2024-01-15T10:30:00Z")

for node in graph.nodes.get():
    print(node.name, node.id)

graph.networks.find_by_ip("10.10.10.1")
graph.networks.find_by_node("1.1.1.1")
graph.networks.find_by_network("10.10.10.0/24")
```

## Вычисление путей

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

## Чтение событий

```python
net = graph.events.get_network_events(last_minutes=60)
for e in net['network_up_down_events']:
    print(e.event_object, e.event_status)

adj = graph.events.get_adjacency_events(
    start_time="2024-01-15T10:00:00Z",
    end_time="2024-01-15T11:00:00Z",
)
```

## Фильтрация линков по атрибутам TE

```python
graph.edges_list(temetric__gte=100)
graph.edges_list(unreserved_bw_0__lt=1e9)
graph.edges_list(src_node="1.1.1.1", dst_node="2.2.2.2", max_link_bw__gt=1e10)
```

Список атрибутов и операторов - в разделе
[Traffic Engineering](../analysis/traffic-engineering.md).

## Туннели MPLS TE

Чтение результата размещения CSPF для туннелей, объявленных на графе:

```python
graph.lsps_list()                                    # every tunnel path
graph.lsps_list(status="unplaced")                   # only what failed to place
graph.lsps_list(via_node="10.10.10.2")               # paths crossing a node
graph.lsps_list(via_edge="10.10.10.1,10.10.10.2")    # paths crossing a link
graph.lsps_list(include_path=True)                   # add the expanded node path

graph.lsp("TUN_R1_R3")                               # one tunnel, path always included
```

Каждый путь содержит `placed`, `cost`, а если размещение не удалось - ещё
`reason`, `reason_code` и `binding_constraints`. `reason_code` разделяет два
вида отказа, которые требуют противоположных действий: `disconnected`
означает, что пути нет даже при снятии всех ограничений (нужно чинить
топологию), а `constraints_unsatisfiable` означает, что путь существует, но
запрос слишком строгий - ослабьте ограничения, перечисленные в
`binding_constraints` (`bandwidth`, `affinity`, `srlg`). Несколько значений
означают, что они блокируют только в комбинации.

Чтобы указать конкретный параллельный/ECMP-линк, используйте `via_edge_key`
вместо `via_edge`; ключ можно получить из
`graph.edges_list(include=["edge_key"])`.

Управление туннелями:

```python
graph.add_lsp({"name": "TUN_R1_R3", "src": "10.10.10.1", "dst": "10.10.10.3",
               "bandwidth": "2G"})
graph.update_lsp("TUN_R1_R3", bandwidth="5G")
graph.delete_lsp("TUN_R1_R3")
graph.delete_lsps()                                  # all tunnels on the graph
```

Проверьте, существует ли путь, удовлетворяющий ограничениям, без создания
туннеля - проверка учитывает пропускную способность, уже занятую
размещёнными туннелями:

```python
graph.cspf_path("10.10.10.1", "10.10.10.7",
                bandwidth="5G",
                metric_type="te",
                admin_exclude_any=["red"],
                srlg_exclude=[1001],
                setup_priority=0)
# {'path': [...], 'cost': 42, 'reason': ''}
```

Обычный кратчайший путь игнорирует туннели - так же, как реальная
IP-маршрутизация без autoroute. Передайте `with_lsps=True`, чтобы
маршрутизировать через туннели с `autoroute`:

```python
graph.paths.shortest("10.10.10.1", "10.10.10.4", with_lsps=True)
```

Сколько TE-полосы пропускания осталось у линка с учётом всех размещённых
туннелей:

```python
graph.edges_list(include=["lsp_left_bw"])
```

Справочник по ключам YAML и правилам размещения CSPF - в разделе
[MPLS TE Tunnels](../analysis/mpls-te-tunnels.md).

## CLI `topo`

SDK устанавливает команду `topo`:

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

## Обработка ошибок

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

**См. также:** [Получение топологии](../ingestion/index.md) ·
[MCP Server](mcp-server.md)

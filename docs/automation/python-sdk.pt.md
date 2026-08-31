# SDK em Python

O **SDK em Python do Topolograph** é um cliente pythônico e orientado a objetos
para a API REST — além de um **coletor SSH** integrado que reúne LSDBs dos seus
dispositivos, e uma CLI `topo` construída sobre ele.

[:simple-pypi: topolograph-sdk no PyPI](https://pypi.org/project/topolograph-sdk/){ .md-button }
[:simple-github: vadims06/topolograph-sdk](https://github.com/Vadims06/topolograph-sdk){ .md-button }

## Instalação

```bash
pip install topolograph-sdk
```

## Conexão

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

!!! info "Autenticação (em ordem de prioridade)"
    1. **Token** como parâmetro — `Topolograph(url=..., token=...)`
    2. **Variável de ambiente** — `export TOPOLOGRAPH_TOKEN=...`
    3. **Basic auth** — `Topolograph(url=..., username=..., password=...)`

## Coletar a topologia via SSH

O SDK pode fazer login nos seus dispositivos, executar os comandos de LSDB
corretos por fabricante, e entregar a você a saída bruta — pronta para envio.
Os comandos exatos por fabricante estão listados na página
[Fornecedores suportados](../reference/supported-vendors.md).

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

### Formato do inventário

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

Obrigatório por host: `hostname`, `username`, `password`, `vendor`
(`cisco`, `juniper`, `frr`, `arista`, `nokia`, `huawei`), e `protocol`
(`ospf` / `isis`). `port` é opcional (o padrão é 22). Um arquivo inicial,
`inventory.yaml.example`, acompanha o projeto.

## Trabalhando com grafos

```python
graphs = topo.graphs.list(protocol="ospf")
graph = topo.graphs.get_by_time("2024-01-15T10:30:00Z")

for node in graph.nodes.get():
    print(node.name, node.id)

graph.networks.find_by_ip("10.10.10.1")
graph.networks.find_by_node("1.1.1.1")
graph.networks.find_by_network("10.10.10.0/24")
```

## Calculando caminhos

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

## Lendo eventos

```python
net = graph.events.get_network_events(last_minutes=60)
for e in net['network_up_down_events']:
    print(e.event_object, e.event_status)

adj = graph.events.get_adjacency_events(
    start_time="2024-01-15T10:00:00Z",
    end_time="2024-01-15T11:00:00Z",
)
```

## Filtrando enlaces por atributos de TE

```python
graph.edges_list(temetric__gte=100)
graph.edges_list(unreserved_bw_0__lt=1e9)
graph.edges_list(src_node="1.1.1.1", dst_node="2.2.2.2", max_link_bw__gt=1e10)
```

Veja [Traffic Engineering](../analysis/traffic-engineering.md) para a lista de
atributos e operadores.

## Túneis MPLS TE

Leia o resultado do posicionamento CSPF dos túneis declarados em um grafo:

```python
graph.lsps_list()                                    # every tunnel path
graph.lsps_list(status="unplaced")                   # only what failed to place
graph.lsps_list(via_node="10.10.10.2")               # paths crossing a node
graph.lsps_list(via_edge="10.10.10.1,10.10.10.2")    # paths crossing a link
graph.lsps_list(include_path=True)                   # add the expanded node path

graph.lsp("TUN_R1_R3")                               # one tunnel, path always included
```

Cada caminho carrega `placed`, `cost`, e — quando falhou — `reason`,
`reason_code` e `binding_constraints`. `reason_code` separa as duas falhas que
exigem correções opostas: `disconnected` significa que não existe caminho nem
mesmo removendo todas as restrições (é preciso corrigir a topologia), enquanto
`constraints_unsatisfiable` significa que existe um caminho, mas a solicitação
é restritiva demais — relaxe as restrições indicadas em `binding_constraints`
(`bandwidth`, `affinity`, `srlg`). Várias entradas indicam que elas só bloqueiam
em combinação.

Use `via_edge_key` em vez de `via_edge` para fixar um enlace paralelo/ECMP
exato; obtenha a chave em `graph.edges_list(include=["edge_key"])`.

Gerenciando túneis:

```python
graph.add_lsp({"name": "TUN_R1_R3", "src": "10.10.10.1", "dst": "10.10.10.3",
               "bandwidth": "2G"})
graph.update_lsp("TUN_R1_R3", bandwidth="5G")
graph.delete_lsp("TUN_R1_R3")
graph.delete_lsps()                                  # all tunnels on the graph
```

Verifique se existe um caminho que satisfaça as restrições, sem criar um
túnel — a verificação leva em conta a largura de banda já reservada pelos
túneis já posicionados:

```python
graph.cspf_path("10.10.10.1", "10.10.10.7",
                bandwidth="5G",
                metric_type="te",
                admin_exclude_any=["red"],
                srlg_exclude=[1001],
                setup_priority=0)
# {'path': [...], 'cost': 42, 'reason': ''}
```

Um caminho mais curto simples ignora os túneis, assim como o encaminhamento IP
real faz sem autoroute. Passe `with_lsps=True` para rotear sobre túneis com
`autoroute`:

```python
graph.paths.shortest("10.10.10.1", "10.10.10.4", with_lsps=True)
```

Quanto de largura de banda de TE ainda resta em um enlace depois de contabilizar
todos os túneis posicionados:

```python
graph.edges_list(include=["lsp_left_bw"])
```

Veja [Túneis MPLS TE](../analysis/mpls-te-tunnels.md) para a referência das
chaves YAML e as regras de posicionamento CSPF.

## A CLI `topo`

O SDK instala um comando `topo`:

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

## Tratamento de erros

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

**Relacionado:** [Obtendo a topologia](../ingestion/index.md) ·
[Servidor MCP](mcp-server.md)

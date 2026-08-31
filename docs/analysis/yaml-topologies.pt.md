# Topologias baseadas em YAML

O Topolograph normalmente constrói um grafo a partir de uma LSDB do
OSPF/IS-IS — mas desde a **v2.32** ele também pode construir um a partir de
uma **definição YAML**. Isso significa que você pode projetar uma topologia
arbitrária do zero (ela nem precisa ser um domínio IGP), mantê-la
atualizada pela API REST e executar sobre ela todas as mesmas análises.

!!! abstract "Network Diagram as a Service"
    LSDB ⇄ YAML é intercambiável **nos dois sentidos**. Você pode projetar
    um domínio IGP do zero *ou* exportar uma LSDB enviada para YAML, depois
    adicionar enlaces, mudar custos e reconferir a reação da rede às suas
    edições.

## Um diagrama básico

Um diagrama YAML é apenas `nodes` e `edges`:

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

Envie-o via API REST:

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

…ou com o [SDK em Python](../automation/python-sdk.md):

```python
from topolograph import Topolograph

topo = Topolograph(url="topolograph-url", token="your-token")
graph = topo.graphs.upload_diagram(yaml_diagram)
print(f"Diagram uploaded: {graph.graph_time}")
```

## Atributos e tags de nós

- O **nome do nó é obrigatório** e deve estar no formato de endereço IP.
  Para exibir algo mais amigável, defina um `label`.
- **Tags são opcionais.** Anexe quaisquer pares `key: value` (os valores
  podem ser strings, números, dicionários ou listas) — por exemplo
  `location`, `ha_role`, ou qualquer coisa relevante para você.

Tags tornam os nós **consultáveis**. Dado um grafo de 6 nós, você pode
selecionar, por exemplo, todos os nós primários no DC1:

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

## Atributos de enlace

Cada enlace tem no mínimo um `src`, `dst` e `cost`. Enlaces também podem
carregar [atributos de Traffic Engineering](traffic-engineering.md)
(largura de banda, métrica de TE, admin group), que você pode então filtrar
através da API de enlaces do diagrama.

## Atributos de rede

Sub-redes terminadas em um nó ficam em uma seção de nível superior
`stub_networks:`. Elas são metadados de terminação, exatamente como quando
uma sub-rede é analisada a partir de uma LSDB real — nenhum nó de grafo é
criado para elas, então contam para a cobertura de backup e para a
pontuação de rede em vez de contar para o número de nós. Uma sub-rede
anunciada por dois ou mais nós é tratada como tendo backup.

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

| key | values / format | meaning |
|---|---|---|
| subnet | CIDR, e.g. `192.168.1.0/24` | the key of each entry; its value is the list of advertising nodes |
| `node` | node name, must exist in `nodes` | node advertising the subnet |
| `cost` | int | cost from that node to the subnet |
| `area` | int | area the subnet is advertised in |
| `metric_type` | int | IS-IS metric style |
| `isnarrow`, `isextended` | bool | IS-IS metric encoding |

Exportar uma topologia de volta para YAML preserva essa seção, então um
ciclo LSDB → YAML → LSDB não perde as sub-redes.

## Túneis MPLS TE

Um diagrama também pode declarar túneis RSVP-TE/SR-TE em uma seção de nível
superior `lsps:`, ao lado de `nodes`/`edges`. O Topolograph executa o
posicionamento CSPF sobre eles (largura de banda, affinity, SRLG) e permite
consultar o resultado, ou verificar se um novo túnel hipotético caberia,
sem tocar no grafo.

```yaml
lsps:
  TUN_R1_R3:
    src: 10.10.10.1
    dst: 10.10.10.3
    bandwidth: 2G
```

[:octicons-arrow-right-24: Túneis MPLS TE](mpls-te-tunnels.md)

## Por que usar

- **Teste uma hipótese antes de construir** — planeje um novo enlace ou LSP,
  modele-o no diagrama YAML e verifique como a rede reconverge.
- **Sirva um diagrama de rede** — construa o grafo a partir de nós e enlaces,
  incluindo metadados como provedor, papel do provedor ou papel do nó. Isso é
  Network Diagram as a Service.

---

**Próximo:** [Atributos de Traffic Engineering →](traffic-engineering.md)

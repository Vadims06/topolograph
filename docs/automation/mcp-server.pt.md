# Servidor MCP

O **Servidor MCP do Topolograph** expõe a API do Topolograph através do
[Model Context Protocol](https://modelcontextprotocol.io/), para que agentes de
LLM (Claude, entre outros) possam consultar topologias, monitorar eventos e
calcular caminhos em tempo real — em linguagem natural, sem integrações de API
sob medida.

[:simple-github: vadims06/topolograph-mcp-server](https://github.com/Vadims06/topolograph-mcp-server){ .md-button }

## Executando

O servidor MCP vem **embutido no
[topolograph-docker](https://github.com/Vadims06/topolograph-docker)** — a
forma mais simples de executá-lo como parte do stack completo:

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
```

Ele sobe em `http://localhost:8000/mcp` e se conecta à API do Topolograph
automaticamente.

### Modo standalone

```bash
pip install -r requirements.txt
export TOPOLOGRAPH_API_BASE="https://your-topolograph-api-url"
export TOPOLOGRAPH_API_TOKEN="your-api-token"   # optional
python mcp-server.py
```

Endpoint padrão: `http://0.0.0.0:8000/mcp`.

## Ferramentas disponíveis

| Ferramenta | Finalidade |
| --- | --- |
| `get_all_graphs` | Lista os grafos disponíveis com filtros |
| `get_graph_by_time` | Busca um grafo específico por horário |
| `get_network_by_graph_time` | Consulta informações de rede (por IP, ID do nó ou máscara) |
| `get_graph_status` | Verifica a saúde e a conectividade do grafo |
| `get_network_events` | Recupera eventos de rede up/down |
| `get_adjacency_events` | Obtém eventos de nós/hosts e enlaces |
| `get_nodes` | Consulta os nós do diagrama |
| `get_edges` | Consulta os enlaces do diagrama |
| `get_shortest_path` | Calcula caminhos mais curtos (com suporte a caminho de backup) |
| `list_vpns` | VNIs e VRFs da fabric, ou as VPNs que um roteador vê |
| `get_routes` | Onde está um MAC ou IP e o que uma VRF ou VNI contém (BGP, EVPN) |
| `get_route_events` | Histórico de rotas, incluindo movimentos de MAC entre VTEPs |
| `upload_graph` | Envia um novo grafo |

## O que isso desbloqueia

Com essas ferramentas conectadas a um agente, você pode fazer perguntas como
*"quais grafos estão conectados agora?"*, *"qual é a rota entre esses dois
IPs?"* ou *"o que mudou depois do último evento de topologia?"* e obter
respostas baseadas no seu IGP real — que é exatamente sobre o que o
[Agente de IA](ai-agent.md) é construído.

---

**Relacionado:** [Agente de IA](ai-agent.md) · [SDK em Python](python-sdk.md) ·
[Início rápido com Docker](../getting-started/quickstart-docker.md)

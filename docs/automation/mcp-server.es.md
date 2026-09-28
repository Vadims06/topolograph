# MCP Server

El **servidor MCP de Topolograph** expone la API de Topolograph a través del
[Model Context Protocol](https://modelcontextprotocol.io/), de modo que los
agentes LLM (Claude y otros) pueden consultar topologías, monitorear eventos
y calcular rutas en tiempo real — en lenguaje natural, sin necesidad de
integraciones de API a medida.

[:simple-github: vadims06/topolograph-mcp-server](https://github.com/Vadims06/topolograph-mcp-server){ .md-button }

## Ejecutarlo

El servidor MCP está **incluido en
[topolograph-docker](https://github.com/Vadims06/topolograph-docker)** — la
forma más sencilla de ejecutarlo como parte de la pila completa:

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
```

Queda disponible en `http://localhost:8000/mcp` y se conecta automáticamente
a la API de Topolograph.

### Independiente

```bash
pip install -r requirements.txt
export TOPOLOGRAPH_API_BASE="https://your-topolograph-api-url"
export TOPOLOGRAPH_API_TOKEN="your-api-token"   # optional
python mcp-server.py
```

Endpoint por defecto: `http://0.0.0.0:8000/mcp`.

## Herramientas disponibles

| Herramienta | Propósito |
| --- | --- |
| `get_all_graphs` | Lista los grafos disponibles con filtrado |
| `get_graph_by_time` | Obtiene un grafo específico por tiempo |
| `get_network_by_graph_time` | Consulta información de red (por IP, ID de nodo o máscara) |
| `get_graph_status` | Verifica el estado y la conectividad del grafo |
| `get_network_events` | Recupera eventos de subida/bajada de red |
| `get_adjacency_events` | Obtiene eventos de nodo/host y de enlace |
| `get_nodes` | Consulta los nodos del diagrama |
| `get_edges` | Consulta los enlaces del diagrama |
| `get_shortest_path` | Calcula rutas más cortas (con soporte de ruta de respaldo) |
| `list_vpns` | VNI y VRF de la fabric, o las VPN que ve un router |
| `get_routes` | Dónde está un MAC o una IP y qué contiene una VRF o un VNI (BGP, EVPN) |
| `get_route_events` | Historial de rutas, incluidos los movimientos de MAC entre VTEP |
| `upload_graph` | Sube un nuevo grafo |

## Qué hace posible

Con estas herramientas conectadas a un agente, puede hacer preguntas como
*"¿qué grafos están conectados en este momento?"*, *"¿cuál es la ruta entre
estas dos IP?"* o *"¿qué cambió después del último evento de topología?"* y
obtener respuestas basadas en su IGP real — que es exactamente sobre lo que
se construye el [agente de IA](ai-agent.md).

---

**Relacionado:** [AI Agent](ai-agent.md) · [Python SDK](python-sdk.md) ·
[Inicio rápido con Docker](../getting-started/quickstart-docker.md)

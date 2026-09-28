# Serveur MCP

Le **serveur MCP Topolograph** expose l'API Topolograph via le
[Model Context Protocol](https://modelcontextprotocol.io/), afin que les
agents LLM (Claude et autres) puissent interroger les topologies, surveiller
les événements et calculer des chemins en temps réel — en langage naturel,
sans code de liaison API sur mesure.

[:simple-github: vadims06/topolograph-mcp-server](https://github.com/Vadims06/topolograph-mcp-server){ .md-button }

## Le lancer

Le serveur MCP est **intégré à
[topolograph-docker](https://github.com/Vadims06/topolograph-docker)** — la
façon la plus simple de l'exécuter dans le cadre de la pile complète :

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
```

Il démarre sur `http://localhost:8000/mcp` et se connecte automatiquement à
l'API Topolograph.

### Autonome

```bash
pip install -r requirements.txt
export TOPOLOGRAPH_API_BASE="https://your-topolograph-api-url"
export TOPOLOGRAPH_API_TOKEN="your-api-token"   # optional
python mcp-server.py
```

Point de terminaison par défaut : `http://0.0.0.0:8000/mcp`.

## Outils disponibles

| Outil | Fonction |
| --- | --- |
| `get_all_graphs` | Lister les graphes disponibles avec filtrage |
| `get_graph_by_time` | Récupérer un graphe spécifique par horodatage |
| `get_network_by_graph_time` | Interroger les informations réseau (par IP, ID de nœud ou masque) |
| `get_graph_status` | Vérifier l'état de santé et la connectivité du graphe |
| `get_network_events` | Récupérer les événements de mise en service/hors service réseau |
| `get_adjacency_events` | Obtenir les événements de nœud/hôte et de lien |
| `get_nodes` | Interroger les nœuds du diagramme |
| `get_edges` | Interroger les liens du diagramme |
| `get_shortest_path` | Calculer les chemins les plus courts (avec prise en charge des chemins de secours) |
| `list_vpns` | VNI et VRF de la fabric, ou les VPN qu'un routeur voit |
| `get_routes` | Où se trouve un MAC ou une IP et ce que contient une VRF ou un VNI (BGP, EVPN) |
| `get_route_events` | Historique des routes, y compris les déplacements de MAC entre VTEP |
| `upload_graph` | Importer un nouveau graphe |

## Ce que cela permet

Avec ces outils connectés à un agent, vous pouvez poser des questions comme
*« quels graphes sont connectés en ce moment ? »*, *« quelle est la route
entre ces deux IP ? »*, ou *« qu'est-ce qui a changé après le dernier
événement de topologie ? »* et obtenir des réponses ancrées dans votre IGP
réel — c'est exactement sur cette base qu'est construit
l'[agent IA](ai-agent.md).

---

**Voir aussi :** [Agent IA](ai-agent.md) · [SDK Python](python-sdk.md) ·
[Démarrage rapide avec Docker](../getting-started/quickstart-docker.md)

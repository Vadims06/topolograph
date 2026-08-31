# MCP Server

**MCP Server Topolograph** предоставляет API Topolograph через
[Model Context Protocol](https://modelcontextprotocol.io/), поэтому
LLM-агенты (Claude и другие) могут запрашивать топологии, отслеживать
события и вычислять пути в реальном времени - на естественном языке, без
написания собственного связующего кода для API.

[:simple-github: vadims06/topolograph-mcp-server](https://github.com/Vadims06/topolograph-mcp-server){ .md-button }

## Запуск

MCP-сервер **входит в состав
[topolograph-docker](https://github.com/Vadims06/topolograph-docker)** - это
самый простой способ запустить его в составе полного стека:

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
```

Он поднимается по адресу `http://localhost:8000/mcp` и автоматически
подключается к API Topolograph.

### Автономный запуск

```bash
pip install -r requirements.txt
export TOPOLOGRAPH_API_BASE="https://your-topolograph-api-url"
export TOPOLOGRAPH_API_TOKEN="your-api-token"   # optional
python mcp-server.py
```

Эндпоинт по умолчанию: `http://0.0.0.0:8000/mcp`.

## Доступные инструменты

| Инструмент | Назначение |
| --- | --- |
| `get_all_graphs` | Список доступных графов с фильтрацией |
| `get_graph_by_time` | Получить конкретный граф по времени |
| `get_network_by_graph_time` | Запрос информации о сети (по IP, ID узла или маске) |
| `get_graph_status` | Проверка состояния и связности графа |
| `get_network_events` | Получение событий появления/пропадания сетей |
| `get_adjacency_events` | Получение событий узлов/хостов и линков |
| `get_events_timeline` | Объединённая лента событий сети и соседств |
| `get_nodes` | Запрос узлов диаграммы |
| `get_edges` | Запрос линков диаграммы |
| `get_shortest_path` | Вычисление кратчайших путей (с поддержкой резервных путей) |
| `get_cspf_path` | Путь с фильтрацией по ограничениям (CSPF), без создания туннеля |
| `get_edge_failure_reaction` | Прогноз влияния на всю сеть при отказе линков |
| `get_lsps` | Список туннелей MPLS TE LSP и результат их размещения через CSPF |
| `add_lsp` | Добавить туннель MPLS TE LSP на граф |
| `update_lsp` | Изменить или переименовать туннель MPLS TE LSP |
| `delete_lsp` | Удалить один туннель LSP или все туннели графа |
| `upload_graph` | Загрузка нового графа |

## Что это даёт

Подключив эти инструменты к агенту, вы можете задавать вопросы вроде *«какие
графы сейчас связны?»*, *«какой маршрут между этими двумя IP?»* или *«что
изменилось после последнего события топологии?»* и получать ответы,
основанные на данных вашего реального IGP - именно на этом построен
[AI Agent](ai-agent.md).

---

**См. также:** [AI Agent](ai-agent.md) · [Python SDK](python-sdk.md) ·
[Быстрый старт с Docker](../getting-started/quickstart-docker.md)

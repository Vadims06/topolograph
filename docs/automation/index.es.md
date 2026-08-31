# Automatización y APIs

Todo lo que puede hacer en la interfaz de Topolograph, puede hacerlo mediante
programación. Elija la superficie que mejor se adapte a su flujo de trabajo:

<div class="grid cards" markdown>

-   :material-language-python:{ .lg .middle } __Python SDK__

    ---

    Cliente REST orientado a objetos, un recolector de LSDB basado en SSH
    (Nornir) y la CLI `topo`.

    [:octicons-arrow-right-24: Python SDK](python-sdk.md)

-   :material-server-network:{ .lg .middle } __MCP Server__

    ---

    Exponga la API de Topolograph a agentes LLM mediante el Model Context Protocol.

    [:octicons-arrow-right-24: MCP Server](mcp-server.md)

-   :material-robot-happy-outline:{ .lg .middle } __AI Agent__

    ---

    Un asistente en lenguaje natural que responde preguntas sobre su IGP en vivo.

    [:octicons-arrow-right-24: AI Agent](ai-agent.md)

</div>

## La API REST subyacente

Todos estos se basan en la API REST de Topolograph. El esquema completo e
interactivo se encuentra en **`/api/ui/`** en su instancia (para el servicio
alojado, [topolograph.com/api/ui](https://topolograph.com/api/ui/)).

Una carga directa es tan simple como:

```python
import requests

r = requests.post(
    'https://topolograph.com/api/graph',
    auth=('youraccount@domain.com', 'your-pass'),
    json={'ospf_data': '<your LSDB text>'},
)
```

Para cualquier cosa más allá de una llamada puntual, el [Python SDK](python-sdk.md)
le ofrece una interfaz mucho más amigable sobre los mismos endpoints.

!!! tip "Diseñado para ser compatible con LLM"
    El modelo de datos de Topolograph se corresponde de forma natural con
    preguntas en lenguaje natural, por eso existen el [servidor MCP](mcp-server.md)
    y el [agente de IA](ai-agent.md) — pregunte "¿cuál es la ruta entre estas
    dos IP?" en lugar de construir una llamada a la API.

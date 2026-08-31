# Automação e APIs

Tudo o que você pode fazer na interface do Topolograph, você pode fazer de forma
programática. Escolha a opção que se encaixa no seu fluxo de trabalho:

<div class="grid cards" markdown>

-   :material-language-python:{ .lg .middle } __SDK em Python__

    ---

    Cliente REST orientado a objetos, um coletor de LSDB via SSH (Nornir) e a
    CLI `topo`.

    [:octicons-arrow-right-24: SDK em Python](python-sdk.md)

-   :material-server-network:{ .lg .middle } __Servidor MCP__

    ---

    Expõe a API do Topolograph a agentes de LLM via Model Context Protocol.

    [:octicons-arrow-right-24: Servidor MCP](mcp-server.md)

-   :material-robot-happy-outline:{ .lg .middle } __Agente de IA__

    ---

    Um assistente em linguagem natural que responde perguntas sobre o seu IGP
    ao vivo.

    [:octicons-arrow-right-24: Agente de IA](ai-agent.md)

</div>

## A API REST por trás de tudo

Todas essas opções são construídas sobre a API REST do Topolograph. O schema
completo e interativo fica disponível em **`/api/ui/`** na sua instância (no
serviço hospedado, [topolograph.com/api/ui](https://topolograph.com/api/ui/)).

Um envio direto é tão simples quanto:

```python
import requests

r = requests.post(
    'https://topolograph.com/api/graph',
    auth=('youraccount@domain.com', 'your-pass'),
    json={'ospf_data': '<your LSDB text>'},
)
```

Para qualquer coisa além de uma chamada pontual, o [SDK em Python](python-sdk.md)
oferece uma interface muito mais amigável sobre os mesmos endpoints.

!!! tip "Projetado para ser amigável a LLMs"
    O modelo de dados do Topolograph mapeia de forma natural para perguntas em
    linguagem natural, e é por isso que o [servidor MCP](mcp-server.md) e o
    [agente de IA](ai-agent.md) existem — pergunte "qual é o caminho entre
    esses dois IPs?" em vez de construir uma chamada de API.

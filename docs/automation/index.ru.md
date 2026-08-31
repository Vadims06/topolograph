# Автоматизация и API

Всё, что можно сделать в интерфейсе Topolograph, можно сделать и программно.
Выберите интерфейс, который подходит вашему сценарию работы:

<div class="grid cards" markdown>

-   :material-language-python:{ .lg .middle } __Python SDK__

    ---

    Клиент REST API Topolograph на Python, SSH-коллектор LSDB (на базе Nornir)
    и CLI `topo`.

    [:octicons-arrow-right-24: Python SDK](python-sdk.md)

-   :material-server-network:{ .lg .middle } __MCP Server__

    ---

    Предоставляет API Topolograph для LLM-агентов через Model Context Protocol.

    [:octicons-arrow-right-24: MCP Server](mcp-server.md)

-   :material-robot-happy-outline:{ .lg .middle } __AI Agent__

    ---

    Ассистент на естественном языке, который отвечает на вопросы о вашей сети
    в реальном времени.

    [:octicons-arrow-right-24: AI Agent](ai-agent.md)

</div>

## REST API в основе

Всё перечисленное построено на REST API Topolograph. Полная интерактивная
схема доступна по адресу **`/api/ui/`** на вашем экземпляре (для облачного
сервиса - [topolograph.com/api/ui](https://topolograph.com/api/ui/)).

Прямая загрузка выглядит так же просто:

```python
import requests

r = requests.post(
    'https://topolograph.com/api/graph',
    auth=('youraccount@domain.com', 'your-pass'),
    json={'ospf_data': '<your LSDB text>'},
)
```

Для чего-то большего, чем разовый вызов, [Python SDK](python-sdk.md) даёт
гораздо более удобный интерфейс к тем же эндпоинтам.

!!! tip "Изначально удобен для LLM"
    Модель данных Topolograph естественно ложится на вопросы на естественном
    языке - именно поэтому существуют [MCP-сервер](mcp-server.md) и
    [AI-агент](ai-agent.md): спросите «какой путь между этими двумя IP?»
    вместо того чтобы формировать вызов API.

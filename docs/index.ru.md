---
title: Topolograph - визуализация и анализ топологии OSPF и IS-IS
hide:
  - navigation
  - toc
---

<div class="tg-hero" markdown>
<div class="tg-hero__copy" markdown>

<h1 class="tg-hero__title">Смотрите на свою сеть OSPF и IS-IS так же, как это делает протокол</h1>

<p class="tg-hero__tagline">
Topolograph строит топологию OSPF/IS-IS по LSDB с одного устройства - затем
позволяет строить основные и резервные пути, моделировать отказы линков и
узлов, планировать метрики и следить за изменениями в IGP в реальном времени.
Локальный запуск, работа офлайн, без логинов и паролей.
</p>

<div class="tg-hero__buttons" markdown>
[Начать работу :material-rocket-launch:](getting-started/quickstart-docker.md){ .md-button .tg-cta }
[Что такое Topolograph? :material-help-circle-outline:](getting-started/what-is-topolograph.md){ .md-button }
[Открыть на GitHub :fontawesome-brands-github:](https://github.com/Vadims06/topolograph){ .md-button }
</div>

</div>
<div class="tg-hero__media" markdown>
![Topolograph - загрузите LSDB и постройте кратчайшие пути](assets/text_file_and_short_paths.gif)
</div>
</div>

<div class="tg-vendors" markdown>
<span>Cisco</span> <span>Cisco NX-OS</span> <span>Juniper</span> <span>Nokia</span>
<span>Huawei</span> <span>FRRouting</span> <span>Arista</span> <span>MikroTik</span>
<span>Palo Alto</span> <span>Fortinet</span> <span>Extreme</span> <span>Bird</span>
<span>Ruckus</span> <span>Allied Telesis</span> <span>Ericsson</span> <span>Ubiquiti</span>
</div>

---

## Что умеет Topolograph

<div class="grid cards" markdown>

-   :material-graph-outline:{ .lg .middle } __Визуализация топологии__

    ---

    Загрузите текстовый файл LSDB или получайте его в реальном времени - и
    получите интерактивный граф OSPF/IS-IS, который в точности отражает то,
    что видят маршрутизаторы.

    [:octicons-arrow-right-24: Получение топологии](ingestion/index.md)

-   :material-vector-polyline:{ .lg .middle } __Построение основных и резервных путей__

    ---

    Вычисляйте кратчайшие пути между любыми двумя узлами, а затем смотрите
    основные и резервные пути и поведение ECMP.

    [:octicons-arrow-right-24: Анализ и визуализация](analysis/visualizing.md)

-   :material-flash-alert:{ .lg .middle } __Симуляция отказов__

    ---

    Выключите линк или маршрутизатор и сразу увидьте, как перестроится
    трафик - до того как настройки будут добавлены в реальную сеть.

    [:octicons-arrow-right-24: Симуляция отказов](analysis/visualizing.md#simulating-failures)

-   :material-radar:{ .lg .middle } __Мониторинг в реальном времени__

    ---

    Запустите OSPF Watcher или IS-IS Watcher, чтобы фиксировать каждое
    изменение соседства, метрики и сети, и отправляйте события в ELK,
    Zabbix или Slack.

    [:octicons-arrow-right-24: Мониторинг в реальном времени](monitoring/index.md)

-   :material-fire:{ .lg .middle } __Поиск слабых мест__

    ---

    Используйте тепловую карту сети и аналитику, чтобы найти самые
    нагруженные линки, единые точки отказа и сети без резервирования.

    [:octicons-arrow-right-24: Тепловая карта сети](analysis/visualizing.md#network-heatmap)

-   :material-robot-happy-outline:{ .lg .middle } __Автоматизация и запросы на естественном языке__

    ---

    Управляйте всем через Python SDK и CLI, REST API, MCP-сервер или
    AI-агента на естественном языке.

    [:octicons-arrow-right-24: Автоматизация и API](automation/index.md)

</div>

## Три способа передать топологию

<div class="grid cards" markdown>

-   __:material-file-document-outline: Текстовый файл__

    Выполните команды показа LSDB на одном маршрутизаторе и сохраните вывод
    в файл. Отлично подходит для разовых разборов, аудита и
    офлайн-планирования "что если".

    [:octicons-arrow-right-24: Загрузка текстового файла](ingestion/text-file.md)

-   __:material-tunnel: Сессия GRE__

    Watcher устанавливает соседство с маршрутизатором через GRE и передаёт
    изменения LSDB в Topolograph в реальном времени.

    [:octicons-arrow-right-24: Сессия GRE](ingestion/gre.md)

-   __:material-transit-connection-variant: Сессия BGP-LS__

    Передавайте LSDB OSPF или IS-IS нативно через BGP-LS, без GRE-туннеля,
    через GoBGP и BGP-LS Watcher.

    [:octicons-arrow-right-24: Сессия BGP-LS](ingestion/bgp-ls.md)

</div>

## Продукты Topolograph

| Компонент | Что это | Документация |
| --- | --- | --- |
| **Topolograph** | Веб-приложение: визуализация, анализ, симуляция, сравнение | [Анализ и визуализация](analysis/index.md) |
| **OSPF Watcher** | Мониторинг изменений OSPF в реальном времени (GRE или BGP-LS) | [OSPF Watcher](monitoring/ospf-watcher.md) |
| **IS-IS Watcher** | Мониторинг изменений IS-IS в реальном времени (GRE или BGP-LS) | [IS-IS Watcher](monitoring/isis-watcher.md) |
| **BMP Watcher** | Сессии BGP, маршруты и контекст VPN в реальном времени (BMP) | [BMP Watcher](monitoring/bmp-watcher.md) |
| **Python SDK** | Объектно-ориентированный API-клиент + SSH-коллектор + CLI `topo` | [Python SDK](automation/python-sdk.md) |
| **MCP Server** | Model Context Protocol для LLM-агентов | [MCP Server](automation/mcp-server.md) |
| **AI Agent** | Сетевой ассистент на естественном языке | [AI Agent](automation/ai-agent.md) |

---

<p style="text-align:center; margin-top:2rem;">
Готовы попробовать? <a href="getting-started/quickstart-docker.md"><strong>Разверните локальный экземпляр в Docker за несколько минут →</strong></a>
</p>

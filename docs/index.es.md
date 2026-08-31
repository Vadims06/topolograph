---
title: Topolograph — visualización y análisis de topología OSPF e IS-IS
hide:
  - navigation
  - toc
---

<div class="tg-hero" markdown>
<div class="tg-hero__copy" markdown>

<h1 class="tg-hero__title">Vea su red OSPF e IS-IS tal como la ve el protocolo</h1>

<p class="tg-hero__tagline">
Topolograph construye su topología OSPF/IS-IS a partir de la base de datos de estado de
enlace (LSDB) de un solo dispositivo — luego le permite trazar rutas más cortas y de
respaldo, simular fallos de enlaces y nodos, planificar costos de enlace y observar los
cambios del IGP en tiempo real. Autoalojado, sin conexión, sin inicios de sesión ni
contraseñas.
</p>

<div class="tg-hero__buttons" markdown>
[Comenzar :material-rocket-launch:](getting-started/quickstart-docker.md){ .md-button .tg-cta }
[¿Qué es Topolograph? :material-help-circle-outline:](getting-started/what-is-topolograph.md){ .md-button }
[Ver en GitHub :fontawesome-brands-github:](https://github.com/Vadims06/topolograph){ .md-button }
</div>

</div>
<div class="tg-hero__media" markdown>
![Topolograph — suba una LSDB y construya rutas más cortas](assets/text_file_and_short_paths.gif)
</div>
</div>

<div class="tg-vendors" markdown>
<span>Cisco</span> <span>Cisco NX-OS</span> <span>Juniper</span> <span>Nokia</span>
<span>Huawei</span> <span>FRRouting</span> <span>Arista</span> <span>MikroTik</span>
<span>Palo Alto</span> <span>Fortinet</span> <span>Extreme</span> <span>Bird</span>
<span>Ruckus</span> <span>Allied Telesis</span> <span>Ericsson</span> <span>Ubiquiti</span>
</div>

---

## Qué puede hacer

<div class="grid cards" markdown>

-   :material-graph-outline:{ .lg .middle } __Visualice la topología__

    ---

    Suba un archivo de texto LSDB o transmítalo en vivo, y obtenga un grafo interactivo
    OSPF/IS-IS que refleja exactamente lo que ven los routers.

    [:octicons-arrow-right-24: Cómo obtener la topología](ingestion/index.md)

-   :material-vector-polyline:{ .lg .middle } __Construya rutas y respaldos__

    ---

    Calcule las rutas más cortas entre dos nodos cualesquiera y luego revele las rutas
    primarias, las de respaldo y el comportamiento de ECMP.

    [:octicons-arrow-right-24: Análisis y visualización](analysis/visualizing.md)

-   :material-flash-alert:{ .lg .middle } __Simule fallos__

    ---

    Apague un enlace o un router y vea al instante cómo se redirige el tráfico — antes de
    tocar la red de producción.

    [:octicons-arrow-right-24: Simulación de fallos](analysis/visualizing.md#simulating-failures)

-   :material-radar:{ .lg .middle } __Monitoree en tiempo real__

    ---

    Ejecute OSPF Watcher o IS-IS Watcher para capturar cada cambio de adyacencia, costo y
    red, y envíe eventos a ELK, Zabbix o Slack.

    [:octicons-arrow-right-24: Monitoreo en tiempo real](monitoring/index.md)

-   :material-fire:{ .lg .middle } __Encuentre puntos débiles__

    ---

    Use el Mapa de calor de red y las analíticas para detectar los enlaces más cargados,
    los puntos únicos de fallo y las redes sin respaldo.

    [:octicons-arrow-right-24: Mapa de calor de red](analysis/visualizing.md#network-heatmap)

-   :material-robot-happy-outline:{ .lg .middle } __Automatice y consulte en lenguaje natural__

    ---

    Controle todo mediante el SDK y la CLI de Python, la API REST, un servidor MCP o un
    agente de IA en lenguaje natural.

    [:octicons-arrow-right-24: Automatización y APIs](automation/index.md)

</div>

## Tres formas de introducir su topología

<div class="grid cards" markdown>

-   __:material-file-document-outline: Archivo de texto__

    Pegue o suba la salida de LSDB de un router. Ideal para análisis puntuales,
    auditorías y planificación offline de escenarios hipotéticos.

    [:octicons-arrow-right-24: Carga de archivo de texto](ingestion/text-file.md)

-   __:material-tunnel: Sesión GRE__

    Un Watcher establece adyacencia con un router mediante GRE y reenvía los cambios de
    estado de enlace en vivo a Topolograph.

    [:octicons-arrow-right-24: Sesión GRE](ingestion/gre.md)

-   __:material-transit-connection-variant: Sesión BGP-LS__

    Transporte el estado de enlace de OSPF o IS-IS de forma nativa a través de BGP-LS —
    sin túnel GRE — mediante GoBGP y el reenviador del Watcher.

    [:octicons-arrow-right-24: Sesión BGP-LS](ingestion/bgp-ls.md)

</div>

## La suite de Topolograph

| Componente | Qué es | Documentación |
| --- | --- | --- |
| **Topolograph** | La aplicación web: visualizar, analizar, simular, comparar | [Análisis y visualización](analysis/index.md) |
| **OSPF Watcher** | Monitoreo en vivo de cambios OSPF (GRE o BGP-LS) | [OSPF Watcher](monitoring/ospf-watcher.md) |
| **IS-IS Watcher** | Monitoreo en vivo de cambios IS-IS (GRE o BGP-LS) | [IS-IS Watcher](monitoring/isis-watcher.md) |
| **BMP Watcher** | Sesiones BGP, rutas y contexto de VPN en vivo (BMP) | [BMP Watcher](monitoring/bmp-watcher.md) |
| **Python SDK** | Cliente de API orientado a objetos + recolector SSH + CLI `topo` | [Python SDK](automation/python-sdk.md) |
| **MCP Server** | Envoltorio de Model Context Protocol para agentes LLM | [MCP Server](automation/mcp-server.md) |
| **AI Agent** | Asistente en lenguaje natural para su IGP | [AI Agent](automation/ai-agent.md) |

---

<p style="text-align:center; margin-top:2rem;">
¿Listo para probarlo? <a href="getting-started/quickstart-docker.md"><strong>Levante una instancia local con Docker en unos minutos →</strong></a>
</p>

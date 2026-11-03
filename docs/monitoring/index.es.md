# Monitoreo en Tiempo Real

Una instantánea de archivo de texto le dice cómo se ve la red *ahora*. Los
**Watchers** le dicen qué está *haciendo* — cada adyacencia que oscila, cada
costo que cambia, cada prefijo que aparece y desaparece — y convierten cada
uno en un evento buscable y con capacidad de generar alertas.

Hay tres Watchers, uno por protocolo, construidos sobre la misma arquitectura:

<div class="grid cards" markdown>

-   :material-router-network:{ .lg .middle } __OSPF Watcher__

    ---

    Monitorea los cambios de topología OSPF en vivo mediante GRE o BGP-LS.

    [:octicons-arrow-right-24: OSPF Watcher](ospf-watcher.md)

-   :material-router-network:{ .lg .middle } __IS-IS Watcher__

    ---

    Lo mismo para IS-IS — incluidos los niveles L1/L2 e IPv6.

    [:octicons-arrow-right-24: IS-IS Watcher](isis-watcher.md)

-   :material-transit-connection-variant:{ .lg .middle } __BMP Watcher__

    ---

    Sesiones BGP, rutas y contexto de VPN y EVPN mediante una estación BMP pasiva.

    [:octicons-arrow-right-24: BMP Watcher](bmp-watcher.md)

</div>


## Qué se ve en Topolograph

Los eventos de un watcher aparecen en el grafo y en su línea de tiempo, en la página Monitoring y en la pestaña Events de un grafo.

En la página del grafo de una red monitorizada, la franja **Momento** está entre la barra de modos y el lienzo. Apila el histograma de eventos, marca en rojo los tramos en que había adyacencias caídas (down) y dibuja una línea discontinua en cada reinicio del watcher. Al arrastrar el cursor, el grafo se redibuja en el navegador; al soltarlo, se abre ese momento, y un enlace que estaba caído se dibuja como estaba. Los botones pasan al evento anterior o al siguiente y alejan el periodo, **Volver al estado actual** regresa al estado vigente y la flecha de la derecha contrae la franja en una pista fina. La pestaña Events conserva sus filtros, el periodo y la tabla. La franja requiere la edición Enterprise.

![La franja Momento sobre el grafo: histograma de eventos con el cursor en el estado actual](../static/ui/moment-strip.png)

![Monitoring: eventos por categoría en el periodo](../static/ui/monitoring-histogram.png)

![Búsqueda de eventos: la tabla filtrada por router, tipo de evento y periodo](../static/ui/event-search.png)

![El grafo en un momento dentro de un intervalo down: la adyacencia caída se dibuja como una línea roja discontinua](../static/ui/moment-down.png)

![La franja Momento contraída en una pista fina, con el tramo rojo del intervalo down](../static/ui/moment-collapsed.png)

![Un cambio de coste de enlace resaltado en el grafo](../static/ui/cost-change-on-graph.png)

## Qué hace un Watcher

Un Watcher escucha de forma pasiva el plano de control del IGP — mediante
una [adyacencia GRE](../ingestion/gre.md) o una
[sesión BGP-LS](../ingestion/bgp-ls.md) — y ante cada cambio:

1. **alimenta la topología** en Topolograph (para que el grafo se mantenga
   actualizado), y
2. **emite un evento** que puede enviarse a uno o más destinos:

```mermaid
flowchart LR
    W[Watcher] --> T[Topolograph<br/>timeline + graph]
    W --> L[Logstash / Fluent Bit]
    L --> E[ELK / Kibana<br/>search & dashboards]
    L --> Z[Zabbix<br/>alarms]
    L --> H[WebHook / Slack<br/>instant notifications]
```

![El Watcher recoge los cambios; Topolograph muestra el pasado, el presente y el futuro](../assets/functional-watcher-role.png)

El Watcher recoge cada cambio del plano de control. Topolograph los guarda como historial: muestra la topología en cualquier momento pasado, su estado actual y el resultado de un fallo o de un cambio de coste antes de que ocurra.

## Eventos detectados

Ambos Watchers detectan las mismas clases de cambio:

- **Adyacencia de vecino** arriba / abajo
- Cambios de **costo de enlace** (métrica anterior → nueva)
- **Redes/prefijos** que aparecen o desaparecen
- **Atributos de TE** — grupo administrativo, ancho de banda
  máximo/reservable/no reservado, métrica de TE
  (consulte [Traffic Engineering](../analysis/traffic-engineering.md))

IS-IS además agrupa todo por **nivel (L1/L2)**.

## Modos de conexión

La configuración de la conexión está en
[Cómo Obtener la Topología](../ingestion/index.md):

- [**Sesión GRE**](../ingestion/gre.md) — ampliamente compatible; necesita
  un túnel GRE y una adyacencia de IGP por área/nivel.
- [**Sesión BGP-LS**](../ingestion/bgp-ls.md) — sin túnel; una única sesión
  transporta todo el dominio. Requiere imagen del Watcher `v3.1.0`+.

## Tamaños de implementación { #deployment-sizes }

Puede empezar tan pequeño como una demo de containerlab y crecer hasta una
pila completa de Watcher + Topolograph + ELK. Una progresión típica:

| # | Deployment | Text logs | View on map | Zabbix / Slack | Search events |
| --- | --- | :---: | :---: | :---: | :---: |
| 1 | Mínimo indispensable (containerlab) | ✅ | ❌ | ❌ | ❌ |
| 2 | Topolograph local + Watcher (ELK apagado) | ✅ | ✅ | ✅ | ❌ |
| 3 | Topolograph local + Watcher + ELK | ✅ | ✅ | ✅ | ✅ |
| 4 | Como el #2 pero **Fluent Bit** en lugar de Logstash | ✅ | ✅ | Solo HTTP/Webhook | ❌ |

El script `install.sh` de
[topolograph-docker](https://github.com/Vadims06/topolograph-docker) puede
levantar Topolograph y un Watcher juntos.

## Heartbeats del Watcher

Cada Watcher puede enviar periódicamente un **heartbeat** (POST) a
Topolograph, así la interfaz lista cada Watcher registrado con un estado de
actividad (`up` / `stale` / `down`) — independientemente de si la red está
produciendo eventos en ese momento.

!!! note "Organizaciones con varios watchers"
    Los Watchers que deban aparecer juntos en la interfaz deben compartir
    **un mismo usuario / token de API de Topolograph**. Requiere
    Topolograph v3.x o posterior.

## Exportación de eventos

<div class="grid cards" markdown>

-   :simple-elasticsearch:{ .lg .middle } __ELK / Kibana__

    ---

    Indexe eventos, búsquelos y construya paneles.

    [:octicons-arrow-right-24: ELK / Kibana](elk-kibana.md)

-   :material-bell-alert:{ .lg .middle } __Zabbix__

    ---

    Genere alarmas por eventos de adyacencia, costo y red.

    [:octicons-arrow-right-24: Zabbix](zabbix.md)

-   :material-webhook:{ .lg .middle } __Webhooks y Slack__

    ---

    Reciba notificaciones instantáneas en su herramienta de chat.

    [:octicons-arrow-right-24: Webhooks y Slack](webhooks.md)

</div>

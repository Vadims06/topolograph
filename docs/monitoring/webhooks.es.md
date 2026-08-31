# Webhooks y Slack

Para notificaciones instantáneas y orientadas a personas, los Watchers
pueden hacer `POST` de cada evento hacia un **WebHook** — que mensajeros
como **Slack** aceptan directamente. En el momento en que una adyacencia cae
o un costo cambia, un mensaje llega a su canal.

## Slack en cuatro pasos

1. **Cree una app de Slack.**
2. **Habilite Incoming Webhooks** para la app.
3. **Cree un Incoming Webhook** — Slack genera una URL.
4. En el `.env` del Watcher, descomente `EXPORT_TO_WEBHOOK_URL_BOOL` y
   establezca la URL generada como `WEBHOOK_URL`.

Eso es todo — los eventos de topología ahora llegan como mensajes de Slack.

!!! tip "Funciona con Fluent Bit"
    La ruta de salida de WebHook/HTTP está disponible tanto con Logstash
    como con el perfil más ligero de [Fluent Bit](elk-kibana.md), así que
    puede obtener notificaciones incluso en una implementación mínima sin
    ELK.

## Qué contiene una notificación

Cada evento es el mismo registro estructurado que el Watcher registra —
marca de tiempo, nombre del watcher, tipo de evento (`host` / `network` /
`metric`), el objeto afectado, estado (`up` / `down` / `changed`), el nodo
que lo detectó, el nombre del grafo de Topolograph, el área/nivel, y el
número de AS. Consulte el
[formato de registro de eventos de OSPF Watcher](ospf-watcher.md#event-log-format)
para un desglose completo campo por campo.

Así, un solo mensaje de Slack le dice, por ejemplo, que *el nodo
`10.10.10.5` detectó que el host `10.10.10.4` cayó en el área 0 / AS 1234*
— con suficiente contexto para entrar directamente en Topolograph y ver el
impacto.

## Cualquier endpoint HTTP

Como es un simple `POST` HTTP, el mismo mecanismo alimenta cualquier
endpoint personalizado — un servicio de automatización interno, un bot de
ChatOps, un pipeline de incidentes — no solo Slack.

---

**Relacionado:** [ELK / Kibana](elk-kibana.md) · [Zabbix](zabbix.md) ·
[Panorama de monitoreo en tiempo real](index.md)

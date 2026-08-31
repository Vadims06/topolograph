# Integración con Zabbix

Si Zabbix es su sistema de referencia para alertas, los Watchers pueden
generar **alarmas** ante cambios de topología — un vecino perdido, el costo
de un enlace de tránsito que cambió, una red retirada — junto al resto de su
monitoreo.

!!! note "Requiere Logstash"
    La ruta a Zabbix usa el perfil por defecto (Logstash). **No** está
    disponible con el perfil Fluent Bit.

## Qué genera alarmas

El Watcher incluye definiciones de Zabbix listas para usar en
`docs/zabbix-ui/`. Se esperan cuatro hosts/items (mismo nombre en host e
item):

| Item | Fires when… |
| --- | --- |
| `ospf_neighbor_up_down` | Se forma una nueva adyacencia, o un dispositivo pierde su vecino |
| `ospf_network_up_down` | Se anuncia o se retira una red desde un nodo |
| `ospf_link_cost_change` | Cambia el costo de un enlace de tránsito (entre vecinos activos) |
| `ospf_stub_network_cost_change` | Cambia el costo de una red stub |

!!! info "Por qué importa el costo de los enlaces de tránsito"
    Los enlaces de tránsito conectan vecinos activos, así que un cambio de
    costo ahí puede desviar las rutas reales/más cortas que sigue su
    tráfico — exactamente el tipo de cambio sobre el que quiere una alarma.

**IS-IS Watcher** provee los items equivalentes de IS-IS (vecino
arriba/abajo, cambio de costo en enlaces de tránsito, retiro de red),
compartiendo el mismo conjunto de plantillas.

## Configurarlo

1. Importe las definiciones de host/item/trigger desde el directorio
   `docs/zabbix-ui/` del Watcher hacia su servidor Zabbix.
2. Apunte la exportación del Watcher hacia Zabbix (configurada mediante el
   pipeline de Logstash / `.env`).
3. Provoque un cambio en un laboratorio (o espere uno real) y confirme que
   la alarma aparece en su panel de Zabbix.

Una vez configurado, las alarmas de topología activas detectadas por el
Watcher aparecen en el panel de Zabbix como cualquier otro problema, con la
vista de últimos datos exponiendo los valores de evento subyacentes.

---

**Relacionado:** [ELK / Kibana](elk-kibana.md) · [Webhooks y Slack](webhooks.md) ·
[OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)

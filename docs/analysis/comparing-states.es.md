# Comparación de Estados de Red

Cada topología que sube es una **instantánea** — la red congelada en el
momento de la captura. Topolograph conserva sus instantáneas a lo largo del
tiempo, lo que significa que puede poner dos de ellas lado a lado y ver
*exactamente* qué cambió.

## El flujo de trabajo clásico

1. **Instantánea antes.** Suba la LSDB actual (o deje que un
   [Watcher](../monitoring/index.md) mantenga instantáneas fluyendo
   automáticamente).
2. **Haga su cambio.** Por ejemplo, redistribuya rutas de BGP hacia OSPF con
   un route-map y una prefix-list, ajuste la métrica de un enlace, o agregue
   una nueva adyacencia.
3. **Instantánea después.** Suba la nueva LSDB.
4. **Compare.** Topolograph resalta las diferencias entre los dos estados.

Como cada carga tiene marca de tiempo, puede comparar dos puntos cualquiera
en el tiempo — no solo los consecutivos.

## Qué muestra una comparación

- **Enlaces** que aparecieron o desaparecieron entre los dos estados.
- **Cambios de costo** en enlaces existentes.
- **Redes/prefijos** que se agregaron o se retiraron.
- **Nodos** que se unieron o abandonaron la topología.

Esto convierte "¿mi cambio hizo lo que esperaba?" en una respuesta visual y
verificable — en lugar de comparar la salida cruda de `show` a simple vista.

## Combina bien con el monitoreo

Las instantáneas manuales antes/después son excelentes para cambios
planificados. Para cambios *no planificados*, un [Watcher](../monitoring/index.md)
registra cada transición de forma continua, así que puede desplazarse por
una línea de tiempo de estados y ver qué cambió y cuándo — y generar alertas
mediante [ELK](../monitoring/elk-kibana.md), [Zabbix](../monitoring/zabbix.md)
o [Slack](../monitoring/webhooks.md).

---

**Siguiente:** [Construya topologías arbitrarias con YAML →](yaml-topologies.md)

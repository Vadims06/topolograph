# API de Monitoreo: eventos, línea de tiempo y estado

Esta página es la referencia de los **campos derivados** que la API REST de
Topolograph calcula para los grafos monitoreados: la línea de tiempo de
eventos (oleadas), el `status` del grafo, y el `object_status` del evento.
Explica qué significa cada valor calculado.

## Línea de tiempo de eventos (oleadas)

La **línea de tiempo de eventos** agrupa los eventos de subida/bajada de
nodo/host en **oleadas** cronológicas para que pueda narrar un incidente de
red (por ejemplo: "la inestabilidad comenzó en T desde el dispositivo X; una
ráfaga de flapping del dispositivo Y; convergió de nuevo en T+n") sin
revisar cientos de eventos crudos. El agrupamiento se calcula del lado del
servidor.

Disponible mediante la API REST de Topolograph en:

```
GET /api/events/{graph_time}/adjacency/timeline
    ?last_minutes=<int>       (optional)
    ?start_time=<ISO8601>     (optional, e.g. 2025-06-30T20:00:00Z)
    ?end_time=<ISO8601>       (optional)
    ?page=<int>               (optional, default 1)
    ?per_page=<int>           (optional, default 20)
```

La lista `waves` está paginada; la respuesta incluye un bloque `pagination`
(`page`, `per_page`, `total`, `total_pages`).

Los eventos solo existen para grafos monitoreados por un watcher. La
respuesta contiene **únicamente resúmenes de oleada** (sin arreglos de
eventos anidados). Para obtener los eventos individuales de una oleada,
vuelva a consultar el endpoint de la API de Topolograph
`GET /api/events/{graph_time}/adjacency` con el `start_ts`/`end_ts` de la
oleada.

## Cómo se detectan las oleadas

Los eventos se colocan en una única línea de tiempo cronológica y se dividen
en oleadas según el tiempo de calma entre ellos: comienza una nueva oleada
cuando el intervalo hasta el siguiente evento supera
`gap_multiplier * median_gap_sec`. Se usa la **mediana** del intervalo (no
el promedio) para que un único período de calma prolongado no distorsione
el umbral.

| Field | Meaning |
|-------|---------|
| `gap_multiplier` | Multiplicador usado para dividir las oleadas (por defecto `5`). |
| `median_gap_sec` | Mediana en segundos entre eventos consecutivos (robusta ante ráfagas). |

## Campos por oleada

| Field | Meaning |
|-------|---------|
| `wave_number` | Índice secuencial de la oleada, comenzando en 1. |
| `start_ts` / `end_ts` | Marcas de tiempo ISO 8601 (`...Z`) del primer/último evento en la oleada. Reutilizables como `start_time`/`end_time` para obtener los eventos de la oleada. |
| `duration_sec` | Segundos desde el primer hasta el último evento de la oleada. |
| `event_count` | Número de eventos en la oleada. |
| `distinct_devices` | Número de dispositivos únicos en la oleada. |
| `trigger_device` | El dispositivo del primer evento en la oleada. |
| `pattern` | Clasificación de la oleada (ver abajo). |
| `converged` | `true` si todo dispositivo que quedó abajo en la oleada se recupera (una subida posterior) dentro de la ventana de tiempo consultada. Una recuperación después de `end_time` no es visible, así que una oleada puede mostrar `converged: false` aunque la red se haya recuperado más tarde fuera de la ventana. |

## Patrones de oleada { #wave-patterns }

`pattern` clasifica una oleada según lo que le sucedió al estado del
dispositivo. Refleja el `status` a nivel de grafo de la API de Topolograph
`GET /api/graph/{graph_time}/status`:

| `pattern` | Meaning | Example | Related graph status |
|-----------|---------|---------|----------------------|
| `outage`  | Al menos un dispositivo queda **abajo** al final de la oleada (cayó y no volvió). | `R1 down` (sin subida posterior); `R1 down, R2 down then up` (R1 sigue abajo) | `critical` |
| `flap`    | Todo lo que cayó **volvió a subir** dentro de la oleada. Independiente del número de dispositivos: 1 dispositivo que cae y sube, o 100 dispositivos que cada uno cae y sube, son ambos `flap`. | `R1 down then up`; `R1..R100 each down then up` | `warning` |
| `up`      | Solo eventos de **subida**, nada cayó en la oleada (una recuperación o una adyacencia completamente nueva). | `R1 up`, `R2 up` | `ok` |

## Ejemplo de respuesta

```json
{
  "graph_time": "10May2025_17h03m00s_7_hosts_ospfwatcher",
  "watcher_name": "demo-watcher",
  "gap_multiplier": 5,
  "median_gap_sec": 10.0,
  "waves": [
    {
      "wave_number": 1,
      "start_ts": "2025-05-10T17:09:24.707000Z",
      "end_ts": "2025-05-10T17:11:27.707000Z",
      "duration_sec": 123.0,
      "event_count": 10,
      "distinct_devices": 6,
      "trigger_device": "10.1.1.3",
      "pattern": "outage",
      "converged": false
    }
  ],
  "pagination": { "page": 1, "per_page": 20, "total": 1, "total_pages": 1 }
}
```

## Estado del grafo

La API de Topolograph `GET /api/graph/{graph_time}/status` devuelve un
`status` general para el grafo, calculado a partir de su conectividad y sus
eventos. Esta es la contraparte a nivel de grafo del `pattern` de una
oleada:

| `status` | When | Related wave `pattern` |
|----------|------|------------------------|
| `critical` | El grafo está **desconectado**, o un nodo cayó y **no** ha vuelto (una bajada persistente). | `outage` |
| `warning` | El grafo está conectado, pero un nodo **cayó y volvió a subir** (un flap), o hay eventos de red abajo o cambios de costo de enlace. | `flap` |
| `ok` | Existen eventos pero son **solo de subida** (recuperaciones de host/red), o no hay eventos en absoluto y el grafo está conectado. | `up` |
| `no_monitoring_data` | El grafo no está monitoreado por un watcher, así que no tiene eventos. | n/a |

`status.details` también incluye:

| Field | Meaning |
|-------|---------|
| `is_monitored` | `true` si el grafo es alimentado por un watcher (solo los grafos monitoreados tienen eventos). |
| `is_connected` | `true` si el grafo de topología está completamente conectado. |
| `up_node_events` / `down_node_events` | Cantidad de eventos de nodo arriba / abajo desde que se recolectó el grafo. |
| `all_host_up_down_events` | Cantidad de todos los eventos de host arriba/abajo (incluidos los recuperados). |
| `network_up_down_events` | Cantidad de eventos de red (subred) arriba/abajo. |
| `adjacency_cost_change_events` | Cantidad de cambios de costo de enlace/adyacencia (métrica cambiada, no una bajada). |
| `top_unstable_devices` | Los N principales `{device, event_count}` ordenados de forma descendente (los más problemáticos). |

## `object_status` del evento

Los eventos crudos (`/adjacency`, `/networks`) llevan un `object_status`
derivado del cambio de costo reportado por el watcher:

| `object_status` | Meaning |
|-----------------|---------|
| `down` | El costo cambió **a** `-1` (la adyacencia/red cayó). |
| `up` | El costo cambió **desde** `-1` (se recuperó o apareció de nuevo). |
| `changed` | El costo cambió entre dos valores reales (cambio de métrica, no una bajada/subida). |

Solo los eventos de host `up`/`down` alimentan las [oleadas](#wave-patterns);
los eventos `changed` son cambios de costo de enlace y se reportan por
separado bajo `adjacency_cost_change_events`.

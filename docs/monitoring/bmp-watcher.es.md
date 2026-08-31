# BMP Watcher

**BMP Watcher** incorpora el plano de control BGP a Topolograph: sesiones de
peering, las rutas que transportan, el contexto de VPN y cada cambio en ambos.

Es una estación [BMP](https://datatracker.ietf.org/doc/html/rfc7854) pasiva. Los
routers abren una sesión TCP hacia ella y envían su Adj-RIB-In. El watcher no
habla BGP, no establece peering y nunca se conecta a un router por su cuenta,
así que no añade ningún estado BGP a la red observada.

!!! info "El estado BGP se mantiene separado de tu grafo IGP"
    Una sesión BGP es una relación de plano de control, no un enlace de
    reenvío. BGP se almacena como un grafo propio, con su propio ciclo de vida,
    y se *vincula* a tus grafos OSPF e IS-IS, nunca se fusiona con ellos. Un
    grafo BGP también funciona por sí solo, sin ningún grafo IGP presente.

---

## Qué se recoge

### Familias de direcciones

| Familia | AFI | SAFI | Se reporta como |
|---|---:|---:|---|
| IPv4 unicast | 1 | 1 | `prefix` |
| IPv6 unicast | 2 | 1 | `prefix` |
| VPNv4 | 1 | 128 | `l3vpn` |
| VPNv6 | 2 | 128 | `l3vpn` |
| EVPN | 25 | 70 | `evpn` |

Una ruta VPN solo es única junto con su Route Distinguisher, de modo que el RD
forma parte de su identidad. Una ruta EVPN no tiene prefijo alguno y se
identifica por los componentes NLRI de la RFC 7432: tipo de ruta, Ethernet
Segment ID, Ethernet Tag, MAC, IP.

### Mensajes BMP

| Mensaje BMP | Qué hace Topolograph con él |
|---|---|
| Route Monitoring | construye la tabla y cada cambio de ruta posterior |
| Peer Up | estado de la sesión y el BGP Identifier del peer — el Router ID al que se atribuyen los eventos |
| Peer Down | cierre de la sesión y un withdraw por cada ruta que ese peer transportaba |
| Initiation / Termination | ciclo de vida de la sesión del colector |
| Statistics Report | se ignora — los contadores no son estado de enrutamiento |

### Flujos de política y nivel de evidencia

Ambos flujos de Adj-RIB-In se almacenan por separado y, donde el speaker soporta
la [RFC 9069](https://datatracker.ietf.org/doc/html/rfc9069), el flujo Loc-RIB se
conserva como una tercera observación:

| Flujo | Evidencia | Significa |
|---|---|---|
| `pre` / `out-pre` | `pre_policy` | el peer la anunció; el router pudo haberla rechazado |
| `post` / `out-post` | `post_policy` | el router la aceptó — un camino candidato |
| `loc-rib` | `loc_rib` | la elección del propio router — el mejor camino instalado |
| `fib` | `fib` | presente en la tabla de reenvío |

Nunca se fusionan. Una ruta vista solo en pre-policy **nunca** se reporta como
seleccionada ni instalada: esa distinción es la razón de que existan ambos
flujos.

### Observaciones, no subredes

El mismo prefijo se almacena una vez por speaker, una por peer, una por path ID
y una por flujo de política. Todas las copias sobreviven, porque "quién anunció
qué a quién" es justamente la pregunta que responde una tabla monitorizada.

---

## Instalar el colector

El colector es [**bmpwatcher**](https://github.com/Vadims06/bmpwatcher), una
estación BMP en Go que separa el volcado inicial de la tabla de los cambios que
llegan después. Su README cubre la compilación, la ejecución en Docker y la
configuración BMP del lado del router para FRR, IOS-XR, Junos y SR OS.

Ejecución mínima, con snapshot y flujo de eventos:

```bash
bmpwatcher \
  --bmp-port=11019 \
  --source-id=pe1 \
  --watcher-name=bmp-dc1 \
  --events=/var/log/bmpwatcher/events.jsonl \
  --topolograph-topology-url=https://topolograph.com/api/watcher/bgp
```

!!! warning "La autenticación aún no está integrada en el colector"
    `/api/watcher/bgp` exige `Authorization: Bearer sk-...`, y el colector
    todavía no añade esa cabecera: un envío directo recibe `401`. Hasta que esté
    disponible, escribe el documento en local con `--topolograph-topology-file`
    y haz el POST tú mismo (ver el ejemplo con `curl` más abajo).

El token se crea en **Settings → API Tokens → Create token**. El workspace se
resuelve a partir del token en el servidor y nunca se toma del payload.

---

## API de ingesta

### `POST /api/watcher/bgp` — el snapshot de topología

El colector reúne la tabla completa durante su ventana de recolección y la envía
como un único documento.

```bash
curl -sS -X POST https://topolograph.com/api/watcher/bgp \
  -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data @topolograph-topology.json
```

```json
{
  "time": "2026-08-17T09:12:03Z",
  "user": "bmp-dc1",
  "srcid": "pe1",
  "sesid": "b4f1c8e2",
  "topology": {
    "nodes": [
      {"name": "10.0.0.1", "asn": "65001", "role": "speaker", "router_ip": "10.0.0.1"},
      {"name": "10.0.0.2", "asn": "65002", "role": "peer"}
    ],
    "edges": [
      {"source": "10.0.0.1", "target": "10.0.0.2",
       "peer_ip": "10.0.0.2", "local_ip": "10.0.0.1", "asn": "65002",
       "peer_type": 0, "policies": ["pre", "post"], "families": ["1/1", "1/128"]}
    ],
    "networks": [
      {"subnet": "192.0.2.0/24", "type": "1", "subtype": 1,
       "bmp_source": "10.0.0.1", "peer_ip": "10.0.0.2",
       "policy": ["post"], "path_id": 0, "nexthop": "10.0.0.2",
       "vpn_rd": "65001:100", "rt": "65001:100",
       "labels": [24001], "data": {}}
    ]
  }
}
```

| Campo | Significado |
|---|---|
| `time` | marca de tiempo del snapshot, ISO 8601 — también la clave de obsolescencia |
| `srcid` | la instancia del colector |
| `sesid` | una *ejecución* del colector; cambia en cada reinicio |
| `nodes[].role` | `speaker` reporta; `peer` solo fue reportado |
| `edges[]` | una **sesión** BGP, no un par de routers |
| `networks[]` | una **observación** de ruta |
| `networks[].type` / `subtype` | AFI como cadena, SAFI como número |
| `networks[].data` | el registro original del colector, para no perder atributos no promovidos |

**Respuesta**

```json
{"graph_time": "17Aug2026_09h12m03s_6_hosts", "checkpoint": false, "routes": 1428}
```

`graph_time` es el identificador público que usan todos los endpoints de lectura
de abajo, con el mismo formato que los grafos IGP.

**Orden y reenvíos.** El `sesid` se genera al arrancar el colector, justo cuando
los speakers vuelven a volcar sus tablas. Dentro de un mismo `sesid` gana el
`time` más reciente; uno anterior o igual se rechaza con `400 stale snapshot`.
Un reenvío completo periódico bajo el mismo `sesid` se trata como un **punto de
control de reconciliación**, no como un grafo nuevo: devuelve `checkpoint: true`,
demuestra que la fuente sigue viva en una red silenciosa y corrige la vista
actual si se ha desviado. Un `sesid` nuevo sustituye a la ejecución anterior.

Todos los Route Target se extraen de `data.base_attrs.ext_community_list`, no
solo del campo `rt` promovido: una ruta con varios RT sigue siendo visible al
buscar por cualquiera de ellos.

### `POST /api/watcher/bgp/events` — el flujo de cambios

Acepta un objeto de evento o una lista de ellos.

```bash
curl -sS -X POST https://topolograph.com/api/watcher/bgp/events \
  -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '[{
        "srcid": "pe1", "sesid": "b4f1c8e2", "seq": 41,
        "watcher_time": "2026-08-17T09:14:11Z",
        "event_name": "prefix", "event_status": "withdraw",
        "event_object": "192.0.2.0/24", "event_detected_by": "10.0.0.2",
        "bmp_source": "10.0.0.1", "policy": "post",
        "afi": 1, "safi": 1, "prefix": "192.0.2.0", "prefix_len": 24,
        "family_data": {"peer_ip": "10.0.0.2"}
      }]'
```

| Campo | Significado |
|---|---|
| `event_name` | `prefix`, `l3vpn`, `evpn`, `peer` |
| `event_status` | `add`, `change`, `withdraw` (rutas); `up`, `down` (peers) |
| `event_detected_by` | el router al que se refiere el cambio |
| `bmp_source` | el speaker que lo reportó — un router distinto en cualquier sesión reflejada |
| `seq` | monótono por `sesid`; deduplicación exacta y detección de huecos |
| `watcher_time` | reloj del colector — ordena el flujo |
| `bmp_timestamp` | reloj del router — solo correlación, nunca orden |
| `replay_suspect` | puede ser la cola de un volcado y no un cambio en vivo |

```json
{"accepted": 1, "duplicates": 0}
```

Un evento cuyo `(srcid, sesid)` no coincide con un snapshot almacenado se
rechaza: **envía la topología antes de arrancar el feed de eventos**. Un `seq`
repetido se cuenta como duplicado y se descarta; un hueco en `seq` se registra
como mensaje perdido.

Un evento de peer up/down es solo informativo. El colector ya emite un withdraw
normal por prefijo para cada ruta que transportaba el peer caído, así que el
evento de peer nunca modifica el estado de rutas.

### `POST /api/watcher/vrfs` — inventario de VRF

Los Route Distinguisher identifican rutas VPN, pero solo el dispositivo conoce el
*nombre* de la VRF y sus Route Target de import/export. Enviar el inventario
permite buscar por nombre de VRF en lugar de por RD.

```bash
curl -sS -X POST https://topolograph.com/api/watcher/vrfs \
  -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
        "router_id": "10.0.0.1",
        "observed_at": "2026-08-17T09:10:00Z",
        "vrfs": [{
          "name": "Red",
          "families": [{
            "afi": "ipv4", "safi": "unicast",
            "route_distinguisher": "65001:100",
            "import_route_targets": ["65001:100", "65001:999"],
            "export_route_targets": ["65001:100"]
          }]
        }]
      }'
```

Cada observación se guarda con su propia marca de tiempo en lugar de sobrescribir
la anterior, de modo que un grafo antiguo todavía puede reconstruir el estado de
la VRF tal como era entonces. La unicidad es `(workspace, router_id, rd)`; un
reenvío sin cambios no escribe nada.

---

## Vinculación con tus grafos IGP

Tras cada guardado BGP **y** cada guardado IGP, Topolograph reevalúa a qué grafos
OSPF o IS-IS pertenece un grafo BGP. Los candidatos se ordenan por solapamiento
de Router ID mediante cobertura de conjuntos voraz, así que un grafo BGP que
abarca dos dominios IGP se vincula a ambos.

| Estado | Significado |
|---|---|
| `bound` | solapamiento de Router ID ≥ 80 %, sin ambigüedad |
| `needs_mapping` | por debajo del umbral, o dos candidatos empatados — pendiente de confirmación |

El solapamiento de Router ID es **evidencia, no un requisito**. Un BGP Router ID
y un OSPF Router ID suelen coincidir, pero Topolograph nunca lo exige: los
resultados ambiguos quedan visibles para que los confirmes.

```bash
# a qué está vinculado un grafo BGP
curl -sS ".../api/bgp-graph/17Aug2026_09h12m03s_6_hosts/bindings" -H "Authorization: Bearer $T"

# confirmar un vínculo a mano
curl -sS -X PUT ".../api/bgp-graph/<bgp_graph_time>/<igp_graph_time>/binding" -H "Authorization: Bearer $T"

# eliminar uno
curl -sS -X DELETE ".../api/bgp-graph/<bgp_graph_time>/<igp_graph_time>/binding" -H "Authorization: Bearer $T"
```

!!! note "IS-IS necesita un Router ID real"
    Internamente, un nodo IS-IS se nombra con un pseudo Router ID acuñado por el
    parser que no existe en ninguna parte de la red. Solo cuenta como identidad
    un **TE Router ID** anunciado por el dispositivo. Un dispositivo que no
    anuncia ninguno no aporta nada a la puntuación de solapamiento, que es el
    resultado honesto y no un fallo. Habilita TE en el dispositivo, o fija el
    Router ID a mano en la página de **mapeo de hostnames**; a partir de ahí
    migra a los grafos siguientes igual que un hostname.

---

## Leer los datos

### Grafos, nodos y sesiones

```bash
GET /api/bgp-graphs?page=1&per_page=50
GET /api/bgp-graph/{bgp_graph_time}
GET /api/bgp-graph/{bgp_graph_time}/nodes?role=rr&asn=65001
GET /api/bgp-graph/{bgp_graph_time}/sessions?igp_relation=inter-domain&bgp_session_type=ebgp
```

Cada sesión se clasifica en cuanto se conocen los vínculos:

| `igp_relation` | Significado |
|---|---|
| `intra-domain` | ambos extremos están en el mismo grafo IGP vinculado |
| `inter-domain` | los extremos están en dos grafos IGP vinculados distintos |
| `external` | al menos un extremo no está en ningún grafo vinculado |

`bgp_session_type` es `ibgp` o `ebgp`, derivado del ASN de la sesión frente al
del propio speaker, no de `AS_PATH[0]`, que una ruta reflejada haría engañoso.

### Búsqueda de rutas

```bash
GET /api/bgp-graph/{bgp_graph_time}/routes?prefix=192.0.2.0/24
GET /api/bgp-graph/{bgp_graph_time}/node/{router_id}/routes?evidence=loc_rib
```

| Parámetro | Comportamiento |
|---|---|
| `prefix=192.0.2.0/24` | coincidencia exacta del prefijo completo |
| `prefix=192.0.2.5` | contención — todas las rutas que cubren la dirección |
| `prefix=192.0.2.0/24&lpm=1` | coincidencia del prefijo más largo, una fila |
| `afi` / `safi` | familia numérica |
| `rd` | Route Distinguisher |
| `vrf` | nombre de VRF, resuelto a sus RD mediante el inventario |
| `rt` | cualquier Route Target de la ruta |
| `policy` / `evidence` | flujo en crudo, o `pre_policy` / `post_policy` / `loc_rib` / `fib` |
| `as_path_contains` | subcadena en cualquier posición del AS_PATH |
| `community` / `large_community` / `extended_community` | búsqueda por community |
| `origin`, `local_pref`, `med`, `originator_id`, `label` | filtros de atributos |
| `peer_ip`, `nexthop`, `bmp_source` | quién la anunció y cómo se alcanza |
| `page`, `per_page` | paginación (`per_page` limitado a 500) |

Cada ruta lleva VRF/RD/RT, AFI/SAFI, política y evidencia, path ID, communities,
next hop, etiquetas y origin.

### Historial y comparación

```bash
# estado de la tabla ahora, o tal como era en un instante
GET /api/bgp-graph/{bgp_graph_time}/routes/state
GET /api/bgp-graph/{bgp_graph_time}/routes/state?at=2026-08-17T09:20:00Z

# qué cambió entre dos instantes
GET /api/bgp-graph/{bgp_graph_time}/routes/compare?t0=...&t1=...

# el feed de eventos y los carriles de la línea de tiempo de monitorización
GET /api/bgp-graph/{bgp_graph_time}/events?last_minutes=60&event_name=peer
GET /api/bgp-graph/{bgp_graph_time}/events/timeline
```

`state` sin `at` lee una vista actual mantenida de forma continua, así que cuesta
el tamaño de la respuesta y no una reproducción de todo el log de eventos. Un
`at` explícito reproduce los deltas desde la línea base del snapshot hasta ese
instante. Los límites de tiempo son inclusivos en ambos extremos.

`compare` devuelve una fila por cambio: `added`, `withdrawn` o `changed` con
antes/después.

En la línea de tiempo de monitorización, `bgp_peer` recibe un marcador por cada
subida o caída de sesión — poco volumen y cada flap importa — mientras que
`bgp_route` se agrupa, de modo que una ráfaga de churn de rutas se dibuja como un
solo marcador con contador en lugar de miles de puntos.

### Route lookup

Route lookup responde a "qué hace realmente este router con este destino", frente
a un SPF puramente topológico.

```bash
GET /api/graph/{graph_time}/route-lookup/{start_node}?destination=192.0.2.5&vrf=Red&with_lsps=1
```

```json
{
  "prefix": "192.0.2.0/24",
  "start_node": "10.0.0.1",
  "route_source": "BGP",
  "admin_distance": 200,
  "nexthop": "10.0.0.9",
  "resolution_chain": ["192.0.2.0/24", "10.0.0.9/32"],
  "path_segments": [{"domain": "17Aug2026_09h05m00s_6_hosts",
                     "path": ["10.0.0.1", "10.0.0.4", "10.0.0.9"]}],
  "warning": null
}
```

El orden de decisión es deliberado:

1. **Coincidencia del prefijo más largo** dentro de la tabla o VRF elegida.
2. **Selección del mejor camino BGP** — un camino por prefijo, por LOCAL_PREF,
   longitud de AS_PATH, ORIGIN y MED, antes de que nada compare protocolos. Una
   observación de Loc-RIB termina la comparación: es la elección del propio
   router.
3. **Distancia administrativa** entre los candidatos supervivientes de distintos
   protocolos.
4. **Resolución recursiva del next hop**, con protección de bucles y
   profundidad.
5. **Transporte IGP SPF/CSPF** hasta ese next hop, opcionalmente por atajos LSP
   elegibles.

| Protocolo | AD |
|---|---:|
| connected | 0 |
| static | 1 |
| eBGP | 20 |
| OSPF | 110 |
| IS-IS | 115 |
| iBGP | 200 |

La distancia administrativa pertenece a las **rutas**, nunca a las aristas de la
topología. Las métricas de OSPF, IS-IS y BGP nunca se comparan entre sí: una
métrica solo tiene sentido dentro de su propio protocolo. iBGP o eBGP lo decide
la sesión por la que se aprendió la ruta, no `AS_PATH[0]`.

Las rutas candidatas se limitan a lo que el nodo inicial ve realmente: su propia
tabla reportada más las tablas de sus vecinos directos de sesión. Un router que
no ejecuta BGP no hereda nada.

---

## Retención

Topolograph conserva los grafos BGP más recientes **por fuente** (`srcid`), de
modo que una instalación con dos colectores mantiene una ventana completa para
cada uno. Cuando una época sale de la ventana, sus rutas y vínculos se van con
ella. Los reenvíos periódicos bajo el mismo `sesid` son puntos de control y no
consumen la ventana.

---

## Límites actuales

- El colector todavía no adjunta el token de API; envía el snapshot con `curl`
  mientras tanto.
- Ejecuta un colector por speaker BMP y define `--source-id`. Varios speakers en
  un colector mezclan sus observaciones.
- Las rutas EVPN se recogen y almacenan, pero la tabla de rutas y route lookup
  están orientadas a prefijos; EVPN todavía no es un objeto de búsqueda de
  primera clase.
- Un Router ID que aparece legítimamente en dos dominios IGP vinculados se
  resuelve a uno de ellos en la clasificación de sesiones.

---

## Véase también

- [bmpwatcher en GitHub](https://github.com/Vadims06/bmpwatcher)
- [OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)
- [Eventos, línea de tiempo y estado](events-timeline.md)
- [Sesión BGP-LS](../ingestion/bgp-ls.md) — BGP-LS transporta topología *IGP*,
  un asunto distinto del estado de enrutamiento BGP de esta página

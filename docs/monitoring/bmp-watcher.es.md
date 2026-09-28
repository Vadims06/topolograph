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
| Peer Up | estado de la sesión y el BGP Identifier del peer - el Router ID al que se atribuyen los eventos |
| Peer Down | cierre de la sesión y un withdraw por cada ruta que ese peer transportaba |
| Initiation / Termination | ciclo de vida de la sesión del colector |
| Statistics Report | se ignora - los contadores no son estado de enrutamiento |

### Flujos de política y nivel de evidencia

Ambos flujos de Adj-RIB-In se almacenan por separado y, donde el speaker soporta
la [RFC 9069](https://datatracker.ietf.org/doc/html/rfc9069), el flujo Loc-RIB se
conserva como una tercera observación:

| Flujo | Evidencia | Significa |
|---|---|---|
| `pre` / `out-pre` | `pre_policy` | el peer la anunció; el router pudo haberla rechazado |
| `post` / `out-post` | `post_policy` | el router la aceptó - un camino candidato |
| `loc-rib` | `loc_rib` | la elección del propio router - el mejor camino instalado |
| `fib` | `fib` | presente en la tabla de reenvío |

Nunca se fusionan. Una ruta vista solo en pre-policy **nunca** se reporta como
seleccionada ni instalada: esa distinción es la razón de que existan ambos
flujos.

---

## Instalar el colector

Para probarlo sin una red real, ejecuta el laboratorio containerlab [13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp) del repositorio bmpwatcher.

El colector es [**bmpwatcher**](https://github.com/Vadims06/bmpwatcher), publicado
como la imagen Docker `vadims06/bmpwatcher:latest`: una estación BMP pasiva a la que los routers
se conectan por TCP 11019; nunca se conecta a un router. Separa el volcado inicial de la
tabla de los cambios que llegan después. Su README cubre la configuración BMP del lado
del router para FRR, IOS-XR, Junos y SR OS.

Necesitas una cuenta de Topolograph: regístrate en topolograph.com o, en una
instancia self-hosted, inicia sesión con el usuario definido en su `.env` (`TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `TOPOLOGRAPH_WEB_API_PASSWORD`).
Crea un token de API: **API → Token → Create Token**. El workspace se resuelve a partir
del token en el servidor y nunca se toma del payload.

### Ejecutar con Docker Compose

El archivo compose del repositorio bmpwatcher ejecuta juntos el colector y el remitente de eventos Fluent Bit:

```bash
git clone https://github.com/Vadims06/bmpwatcher.git && cd bmpwatcher
cp .env.example .env
docker compose --profile collector up -d
```

Define en `.env`:

- `TOPOLOGRAPH_HOST`: la dirección IP del host Docker, no `localhost`, porque Topolograph y BMP Watcher corren en sus propias redes de contenedores; `topolograph.com` para la instancia pública.
- `TOPOLOGRAPH_PORT`: `8080` por defecto, `443` para topolograph.com.
- `WEBHOOK_TLS_ON`: `off` para un Topolograph self-hosted, `on` para topolograph.com.
- `TOPOLOGRAPH_API_TOKEN`: el token `sk-...`.
- `SOURCE_ID`: el nombre de este colector en Topolograph, p. ej. `dc1-rr`. Mantenlo estable: un contenedor recreado con el mismo nombre conserva sus datos juntos.
- `BMPWATCHER_LOG_DIR`: dónde escribe el colector sus archivos, `/var/log/bmpwatcher` por defecto.

Se detiene con el mismo perfil: `docker compose --profile collector down`. Habilita Docker al inicio (`systemctl enable docker`): los contenedores se reinician tras un fallo y un reinicio.

El primer snapshot sale cuando cada router terminó de volcar su tabla: unos 30 segundos después de que dejan de llegar sus rutas, como máximo 5 minutos después de la primera. Comprueba que se envió:

```bash
docker logs bmpwatcher 2>&1 | grep 'topology posted'
```

### EVPN: primeros mensajes

*Topolograph v2.73 o posterior, BMP Watcher v1.1.0 o posterior. La exportación EVPN está verificada en FRR.*

Las preguntas de EVPN se responden sobre tu grafo OSPF o IS-IS, así que
Topolograph necesita uno cuyos Router ID coincidan con los BGP speakers.

1. **Consigue el grafo IGP.** Para tu red, sube su LSDB o ejecuta
   [OSPF Watcher](ospf-watcher.md) / [IS-IS Watcher](isis-watcher.md). Para el
   laboratorio [13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp), su underlay OSPF es el grafo de
   demostración de 13 routers que Topolograph crea en cada cuenta en el primer
   inicio de sesión; para IS-IS, sube [demo_isis_LSDB.txt](https://github.com/Vadims06/topolograph/blob/master/demo_isis_LSDB.txt) como FRR
   IS-IS.
2. **Activa BMP en los route reflectors**: tienen las rutas EVPN de todos los
   leaves, mientras que un leaf exporta solo lo que aprendió. FRR carga BMP como
   módulo, así que añade `-M bmp` a `bgpd_options` y reinicia FRR:

```
# /etc/frr/daemons
bgpd_options="   --daemon -M bmp -A 127.0.0.1"
```

```
router bgp 65000
 bmp targets topolograph
  bmp connect 198.51.100.10 port 11019 min-retry 1000 max-retry 2000
  bmp monitor l2vpn evpn pre-policy
  bmp monitor l2vpn evpn post-policy
```

En containerlab, edita el archivo `daemons` del laboratorio y vuelve a desplegarlo:
reiniciar FRR dentro de un contenedor en marcha corta sus enlaces. En `bmp connect`
usa una dirección del host del colector que los routers alcancen por TCP 11019; en
containerlab es la puerta de enlace de la red de gestión del laboratorio
(`docker network inspect <mgmt-network>`).

3. **Arranca el colector** como arriba.
4. **Comprueba la respuesta en el grafo IGP**: el grafo cuyos `protocols`
   incluyen `bgp`, sus VNI y VRF, y los leaves de un VNI.

```bash
TOPOLOGRAPH_URL=http://<host-ip>:8080   # https://topolograph.com para la instancia pública
curl -sS "$TOPOLOGRAPH_URL/api/graph/?protocol=bgp" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
curl -sS "$TOPOLOGRAPH_URL/api/graph/<graph_time>/vpns" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
curl -sS "$TOPOLOGRAPH_URL/api/graph/<graph_time>/nodes?protocol=bgp&vni=<vni>" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
```

Una lista `?protocol=bgp` vacía significa que el grafo BGP aún no está
vinculado: revisa `GET /api/bgp-graph/<bgp_graph_time>/bindings`. La tabla
inicial llega en el snapshot; el flujo de eventos solo trae los cambios
posteriores.

Cada cuenta tiene un grafo BGP de demostración capturado
en el laboratorio 13-hosts-demo-bgp y vinculado al mismo grafo de demostración, así que
en ese grafo las respuestas incluyen también las rutas de demostración.

---

## Vinculación con tus grafos IGP

Tras cada guardado BGP **y** cada guardado IGP, Topolograph reevalúa a qué grafos
OSPF o IS-IS pertenece un grafo BGP. Los candidatos se ordenan por solapamiento
de Router ID mediante cobertura de conjuntos voraz, así que un grafo BGP que
abarca dos dominios IGP se vincula a ambos.

| Estado | Significado |
|---|---|
| `bound` | solapamiento de Router ID ≥ 80 %, sin ambigüedad |
| `needs_mapping` | por debajo del umbral, o dos candidatos empatados - pendiente de confirmación |

Un grafo BGP se vincula primero al grafo IGP vigente en su propio momento: el
más reciente que no sea posterior al grafo BGP. Los snapshots IGP tomados
después, mientras siga siendo el grafo BGP más reciente de su fuente, también se
vinculan, siempre que conserven los routers de la primera coincidencia. Un
router que se unió después del snapshot IGP se cuenta por sus eventos de
adyacencia OSPF.

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

## Consultar los datos BGP

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
| `prefix=192.0.2.5` | contención: todas las rutas que cubren la dirección, primero el prefijo más largo |
| `mac`, `vni` | solo EVPN, ver [EVPN](#evpn) |
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
subida o caída de sesión - poco volumen y cada flap importa - mientras que
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
2. **Selección del mejor camino BGP** - un camino por prefijo, por LOCAL_PREF,
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

## EVPN

*Topolograph v2.73 o posterior, BMP Watcher v1.1.0 o posterior.*

BGP EVPN sobre VXLAN (AFI 25 / SAFI 70) se lee del flujo BMP de los route
reflectors. Toda pregunta de EVPN se hace a tu grafo OSPF o IS-IS: la responde
el grafo BGP vinculado a él, y cada VTEP se resuelve al router dueño de la
dirección, así que un camino hacia un host termina en el leaf que está detrás.

### Tipos de ruta

| Tipo de ruta | RFC | Se usa para |
|---|---|---|
| 1 Ethernet Auto-Discovery | [RFC 7432](https://datatracker.ietf.org/doc/html/rfc7432) | se almacena y se puede buscar |
| 2 MAC/IP Advertisement | RFC 7432 | dónde está un host: MAC, IP, VNI, VTEP, ESI; movimientos de MAC |
| 3 Inclusive Multicast Ethernet Tag | RFC 7432, [RFC 6514](https://datatracker.ietf.org/doc/html/rfc6514) | qué leaves son VTEP de un VNI (el VNI viene del atributo PMSI Tunnel) |
| 4 Ethernet Segment | RFC 7432 | se almacena y se puede buscar |
| 5 IP Prefix | [RFC 9136](https://datatracker.ietf.org/doc/html/rfc9136) | subredes de una VRF y su L3VNI |

### Atributos de la ruta

Una ruta EVPN lleva los habituales RD, route targets, next hop y communities,
además de un objeto `evpn`:

| Campo | Significado |
|---|---|
| `route_type` | de 1 a 5 |
| `mac` | MAC del host (RT-2) |
| `ip`, `ip_len` | IP del host (RT-2), prefijo y su longitud (RT-5), router de origen (RT-3, RT-4) |
| `vni` | L2VNI (RT-2, RT-3) |
| `l3vni` | L3VNI de la VRF (RT-5, y RT-2 con symmetric IRB) |
| `esi` | Ethernet Segment ID; todo ceros significa host conectado a un solo leaf |
| `eth_tag` | Ethernet Tag ID |
| `vtep` | el VTEP: el router de origen para RT-3 y RT-4, el next hop para las demás |
| `mm_seq` | número de secuencia de MAC Mobility ([RFC 7432 §15](https://datatracker.ietf.org/doc/html/rfc7432#section-15)) |

En RT-2 y RT-5 también se rellena `prefix` (la dirección del host en /32 o
/128, o el prefijo RT-5), así que `prefix=` encuentra hosts y subredes EVPN
como cualquier otra ruta.

```json
{
  "afi": 25, "safi": 70, "rd": "1:123.123.31.31:5",
  "route_targets": ["65000:1020"], "nexthop": "123.123.31.31",
  "evpn": {"route_type": 2, "mac": "00:c1:ab:00:00:03", "ip": null, "ip_len": null,
           "vni": 1020, "l3vni": null, "esi": "00:00:00:00:00:00:00:00:00:00",
           "eth_tag": 0, "vtep": "123.123.31.31", "mm_seq": null}
}
```

### Preguntas que responde

Todas se hacen al grafo IGP (`{graph_time}`), sin el tiempo del grafo BGP.

| Pregunta | Petición |
|---|---|
| ¿Qué VNI y VRF tiene la fabric? | `GET /api/graph/{graph_time}/vpns` |
| ¿Qué VPN ve un router? | `GET /api/graph/{graph_time}/node/{router_id}/vpns` |
| ¿Qué leaves llevan el VNI 1020 o la VRF tenant1? | `GET /api/graph/{graph_time}/nodes?protocol=bgp&vni=1020` (o `vrf=tenant1`) |
| ¿Dónde está un host: leaf, VNI, VRF, MAC? | `GET /api/graph/{graph_time}/routes?prefix=10.10.20.13` o `?mac=00:c1:ab:00:00:03` |
| ¿El host es multihomed? | la misma petición: varios VTEP con un mismo `esi` distinto de cero |
| ¿Qué enruta una VRF? | `GET /api/graph/{graph_time}/routes?vrf=tenant1` |
| ¿Qué tiene un leaf para un VNI? | `GET /api/graph/{graph_time}/node/{router_id}/routes?vni=1010` |
| ¿Se movió un MAC, de qué leaf a cuál, cuándo? | `GET /api/events/{graph_time}/routes?mac=00:c1:ab:00:00:01&last_minutes=60` |
| ¿Cómo alcanza el underlay todos los VTEP de un VNI? | `GET /api/graph/{graph_time}/path/{node_a}/{vtep1},{vtep2}` |

`routes` también acepta `at=` para un momento pasado, y `vtep=`, `rt=`, `rd=`,
`page`, `per_page`. En el historial de eventos, la fila en la que un MAC
aparece en un VTEP nuevo lleva `moved_from_vtep`. El mismo MAC anunciado por
varios VTEP con un mismo ESI es multihoming, no un movimiento.

Una fila de VPN agrupa las rutas por nombre de VRF cuando el inventario de VRF
lo conoce, si no por route target; un bridge domain EVPN es una fila por L2VNI:

```json
{"name": null, "vni": 1020, "l3vni": 5000,
 "route_targets": ["65000:1020", "65000:5000"],
 "route_distinguishers": ["1:123.123.30.30:5", "1:123.123.31.31:5"],
 "prefix_count": 4}
```

En la interfaz, las mismas respuestas están en el formulario de camino BGP / VPN
y en Graph table, BGP Routes, que tiene columnas para cada campo de arriba. Un
recorrido paso a paso con los datos de demostración está en el
[BGP how-to](https://topolograph.com/how-to/bgp#evpn), y el laboratorio en el que se capturaron es
[containerlab/13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp).

---

## Límites actuales

- EVPN asume VNI globales en toda la fabric: los VNI de significado local
  (RFC 8365) no están soportados.
- Qué leaf es el designated forwarder de un Ethernet Segment lo deciden los
  propios leaves y no viaja por BMP.
- Un Router ID que aparece legítimamente en dos dominios IGP vinculados se
  resuelve a uno de ellos en la clasificación de sesiones.

---

## Véase también

- [bmpwatcher en GitHub](https://github.com/Vadims06/bmpwatcher)
- [OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)
- [Eventos, línea de tiempo y estado](events-timeline.md)
- [Sesión BGP-LS](../ingestion/bgp-ls.md) - BGP-LS transporta topología *IGP*,
  un asunto distinto del estado de enrutamiento BGP de esta página

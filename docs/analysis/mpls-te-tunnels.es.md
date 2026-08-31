# Túneles MPLS TE

Además de las [topologías basadas en YAML](yaml-topologies.md) y los
[atributos de Traffic Engineering](traffic-engineering.md), un diagrama
puede declarar **túneles MPLS TE** (estilo RSVP-TE o SR-TE) en una sección
de nivel superior `lsps:`. Topolograph ejecuta la colocación CSPF
(Constrained Shortest Path First) sobre ellos — las mismas restricciones de
ancho de banda/afinidad/SRLG que un router real, sin ninguna señalización —
y visualiza el resultado.

![Túneles MPLS TE: tabla de LSP y rutas colocadas en el grafo](../static/mpls-lsp-graph-and-table.png)

La pestaña **LSP tunnels** lista cada ruta con su estado de colocación,
motivo de fallo, ancho de banda y prioridades; seleccionar un nodo muestra
los túneles que son de ingreso, tránsito o egreso en él, y las rutas
colocadas se dibujan en el lienzo.

!!! info "Por ahora, solo diagramas YAML"
    `lsps:` está disponible en diagramas basados en YAML. El soporte para
    túneles reportados en vivo por un watcher está planificado para una
    versión posterior.

## Un túnel en YAML

```yaml
lsps:
  TUN_R1_R3:                    # key = tunnel name
    src: 10.10.10.1
    dst: 10.10.10.3
    metric_type: te             # igp (default) | te
    bandwidth: 2G                # applies to every path unless overridden
    setup_priority: 7
    admin_groups:
      exclude-any: [red]
    color: "#ff9900"
    autoroute: false             # see "autoroute" below
    paths:                       # = LSPs; omit entirely for one dynamic primary
      primary:
        ero:
          - 10.10.10.2                        # plain string = loose hop
          - {node: 10.10.10.3, hop: strict}    # explicit form for a strict hop
      secondary:
        role: standby
        bandwidth: 1G            # overrides the tunnel-level default
        srlg_exclude: [1001]
```

## Referencia de claves

| key | level | values / format | meaning |
|---|---|---|---|
| `lsps` | top-level | dict, tunnel name → body | sección opcional junto a `nodes`/`edges` |
| `src`, `dst` | tunnel | node name (IP-address format) | extremos del túnel |
| `metric_type` | tunnel | `igp` (default) \| `te` | qué métrica optimiza CSPF |
| `bandwidth` | tunnel/path | `2G`, `500M`, or a raw bps number | ancho de banda requerido; una ruta sobrescribe el valor por defecto del túnel |
| `setup_priority` | tunnel/path | `0`–`7`, default `7` | pool de admisión de RSVP-TE (`0` es el más fuerte) |
| `hold_priority` | tunnel/path | `0`–`7`, defaults to `setup_priority` | pool en el que se mantiene la reserva; no puede ser más débil que la prioridad de establecimiento |
| `admin_groups` | tunnel/path | dict: `exclude-any` / `include-any` / `include-all` → list of names | filtro de afinidad |
| `srlg_exclude` | path | list of int | restricción de SRLG |
| `color` | tunnel | CSS color | color de resaltado en el lienzo |
| `autoroute` | tunnel | bool, default `false` | ver más abajo |
| `paths` | tunnel | dict, path name → body; omitted = one dynamic `primary` | los LSP del túnel |
| `role` | path | `primary` (default) \| `secondary` \| `standby` | rol de la ruta |
| `ero` | path | list: `10.10.10.2` (loose hop) or `{node: ..., hop: strict}` | ruta explícita |

Una ruta hereda `bandwidth`, `setup_priority`, `hold_priority` y
`admin_groups` del túnel cuando los omite. `srlg_exclude` y `ero` **no** se
heredan — declarar `srlg_exclude` a nivel de túnel no tiene efecto,
establézcalo en cada ruta que lo necesite.

Los enlaces declaran los mismos atributos de TE cubiertos en la
[página de Traffic Engineering](traffic-engineering.md#what-topolograph-parses)
(`temetric`, `max_rsrv_link_bw`, `admin_group`/afinidad, `srlg`,
`unreserved_bw_0`…`unreserved_bw_7`) — sin nomenclatura aparte para fines de
MPLS.

### `autoroute`

Un **LSP señalizado no redirige el tráfico por sí solo** — eso coincide con
el comportamiento real de RSVP-TE/SR-TE: sin `autoroute announce` (o una
ruta estática explícita que apunte al túnel), un túnel es solo ancho de
banda reservado, invisible para el cálculo de rutas al estilo IGP.
Establezca `autoroute: true` en un túnel para que actúe como un atajo de
reenvío en las consultas de ruta extremo a extremo (vea `with_lsps` más
abajo) — el equivalente en el mundo real a activar autoroute en el headend.

### Prioridad de establecimiento y retención

`0` es la prioridad más fuerte y `7` la más débil. Deje `hold_priority` sin
especificar y seguirá a `setup_priority`, igual que el `priority <setup>`
de un router con el segundo valor omitido.

Un túnel establecido con una prioridad fuerte pero retenido con una débil
sería desalojable en el momento en que se señaliza, así que esa combinación
se rechaza: `hold_priority` debe ser al menos tan fuerte como
`setup_priority` (`setup_priority: 0` con `hold_priority: 7` es un error de
validación, `setup_priority: 7` con `hold_priority: 0` está bien).

### Claves (operacionales) rechazadas

`rro`, `oper_status`, `active_lsp_name`, y cualquier clave `label_*` son
**rechazadas** en `lsps:` — describen estado de señalización en vivo
(Record Route, estado actual, ruta activa), no intención declarada, y solo
tienen sentido una vez que un watcher real las reporta. Se genera un error
de validación si incluye alguna.

## Colocación CSPF

En cada guardado, Topolograph coloca cada ruta en orden de `setup_priority`
(convención RSVP-TE: `0` es la más alta), con las mismas reglas que
aplicaría un router real:

- filtra los enlaces que no tienen suficiente ancho de banda en el pool de
  `setup_priority` solicitado, no satisfacen el filtro de afinidad, o están
  en un SRLG excluido;
- ejecuta la ruta más corta sobre lo que queda, respetando cualquier `ero`
  (un salto `strict` debe ser un enlace directo desde el salto anterior — el
  LSP falla en lugar de ser enrutado silenciosamente alrededor de él);
- resta el ancho de banda colocado de ese pool (y de cada pool de prioridad
  inferior) antes de colocar la siguiente ruta.

La colocación nunca modifica los atributos de TE anunciados
(`unreserved_bw_*`) — la capacidad consumida se rastrea por separado, así
que volver a ejecutar la colocación siempre parte de los números realmente
anunciados.

Los empates de ECMP se resuelven de forma determinista: menor número de
saltos, luego orden lexicográfico de los nombres de nodo.

## Leer los resultados de colocación

`GET /api/graph/{graph_time}/lsps` y `GET /api/graph/{graph_time}/lsps/{name}`
devuelven el resultado de colocación de cada ruta junto con su configuración
declarada:

```json
{
  "name": "TUN_R1_R3",
  "src": "10.10.10.1",
  "dst": "10.10.10.3",
  "paths": {
    "primary": {
      "placed": true,
      "reason": null,
      "cost": 20,
      "path": ["10.10.10.1", "10.10.10.2", "10.10.10.3"]
    },
    "secondary": {
      "placed": false,
      "reason": "insufficient bandwidth",
      "cost": null,
      "path": []
    }
  }
}
```

`reason` explica en palabras *por qué* falló una ruta no colocada. Junto a
él, `reason_code` da la categoría legible por máquina y
`binding_constraints` nombra qué es lo que realmente está bloqueando:

| `reason_code` | meaning | what to do |
|---|---|---|
| `disconnected` | no existe ninguna ruta aunque se eliminen todas las restricciones | repare la topología |
| `constraints_unsatisfiable` | existe una ruta, la solicitud es demasiado estricta | relaje las restricciones en `binding_constraints` (`bandwidth`, `affinity`, `srlg`) |
| `ero_strict_hop_unreachable` | un salto estricto no tiene enlace desde el salto anterior | corrija el `ero` |
| `endpoint_not_found` | `src`/`dst` no está en el grafo | corrija el extremo |

Varias entradas en `binding_constraints` juntas significan que solo
bloquean en combinación — eliminar cualquiera de ellas es suficiente.

Filtros útiles en el endpoint de lista:

```python
# Which tunnels failed to place, and why
graph.lsps_list(status="unplaced")

# Which tunnels cross a given node or link (pre-maintenance impact check)
graph.lsps_list(via_node="10.10.10.2")
graph.lsps_list(via_edge="10.10.10.1,10.10.10.2")
```

Cuánto ancho de banda de TE queda en un enlace, después de contabilizar
cada túnel colocado:

```python
graph.edges_list(include=["lsp_left_bw"])
# -> ..., "lsp_left_bw_7": ..., "lsp_reserved_bw": "7Gbps",
#    "lsp_left_bw": "3Gbps", "lsp_bandwidth_usage": "7Gbps/3Gbps"
```

## Ruta CSPF, sin declarar un túnel

`cspf_path` responde "qué ruta satisface estas restricciones, y a qué
costo" — un cálculo de ruta más corta filtrado por restricciones, la misma
clase de consulta que una ruta más corta simple. No se crea ni persiste
nada:

```python
result = graph.cspf_path(
    "10.10.10.1", "10.10.10.7",
    bandwidth="5G",
    admin_exclude_any=["red"],
)
# {'path': [...], 'cost': 42, 'reason': ''}
# or, if nothing fits: {'path': [], 'cost': None, 'reason': 'no path ... satisfies the requested constraints: ...'}
```

La respuesta tiene en cuenta el ancho de banda que **ya retienen los
túneles declarados**: en una topología con una sección `lsps:` la
comprobación se ejecuta contra lo que le queda a cada enlace después de la
colocación, no contra el valor anunciado, así que el resultado nunca
promete capacidad que ya está tomada. Las restricciones se evalúan por
prioridad de establecimiento, así que un enlace puede estar lleno en una
prioridad y aun así tener espacio en una más fuerte.

Las restricciones de afinidad (`admin_exclude_any`, `admin_include_any`,
`admin_include_all`) coinciden con los **nombres** de afinidad en el
enlace. Las topologías obtenidas de una red en vivo anuncian el grupo
administrativo como una máscara de bits, así que un `include-any`/
`include-all` basado en nombres en esos grafos no coincide con nada y la
respuesta es "no path" — use `exclude-any` o una topología YAML con
afinidades nombradas en ese caso.

## Ruta extremo a extremo mediante túneles (`with_lsps`)

Por defecto, `graph.paths.shortest(src, dst)` es una ruta de IGP simple —
no afectada por ningún túnel del grafo, igual que el reenvío IP real sin
autoroute. Pase `with_lsps=True` para tener en cuenta los túneles con
`autoroute: true` como atajos de reenvío:

```python
graph.paths.shortest("10.10.10.1", "10.10.10.4")               # plain IGP path
graph.paths.shortest("10.10.10.1", "10.10.10.4", with_lsps=True) # via active autoroute tunnels
```

## Qué se rompe si un enlace cae

`edge_failure_reaction` predice el impacto en toda la red de que uno o más
enlaces fallen — conectividad, y qué enlaces ganan o pierden tráfico:

```python
graph.paths.edge_failure_reaction([("10.10.10.1", "10.10.10.2")])
# {'isGraphStillConnected': True, 'affectedLinks': {...}, 'disjointedNodes': []}
```

Para una vista por túnel de la misma pregunta, combínelo con
`lsps_list(via_edge=...)` para ver qué túneles atraviesan el enlace antes de
comprobar el impacto de su fallo.

---

**Relacionado:** [Topologías Basadas en YAML](yaml-topologies.md) ·
[Atributos de Traffic Engineering](traffic-engineering.md) ·
[Python SDK](../automation/python-sdk.md)

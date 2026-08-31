# Traffic Engineering (TE)

Más allá del costo básico de IGP, OSPF e IS-IS pueden transportar atributos
de **Traffic Engineering** — ancho de banda, una métrica de TE separada y
grupos/afinidades administrativos. Topolograph los analiza y los pone a
disposición para una visualización y filtrado más completos, tanto para
**OSPF** como para **IS-IS**.

!!! info "TE es opcional"
    Su grafo se construye bien solo con LSA 1/2/5 (OSPF) o la LSDB estándar
    de IS-IS. Los datos de TE son *adicionales* — actívelos cuando necesite
    un análisis consciente de la capacidad.

## Qué analiza Topolograph { #what-topolograph-parses }

| Attribute | API/SDK name | Meaning |
| --- | --- | --- |
| TE default metric | `temetric` | métrica de enlace específica de TE (independiente del costo de IGP) |
| Administrative group | `admin_group` | afinidad / color / clase de recurso |
| Maximum link bandwidth | `max_link_bw` | capacidad física del enlace |
| Maximum reservable bandwidth | `max_rsrv_link_bw` | ancho de banda disponible para reserva |
| Unreserved bandwidth (per priority) | `unreserved_bw_0` … `unreserved_bw_7` | ancho de banda restante en cada una de las 8 prioridades de TE |
| Shared risk link group | `srlg` | lista de ID de SRLG a los que pertenece el enlace (RFC 4203 / RFC 5307) |

Se usan los **mismos nombres de atributo** sin importar si los datos vinieron
de OSPF o de IS-IS.

## Cómo introducir datos de TE

=== "OSPF — archivo de texto"

    Incluya **`show ip ospf database opaque-area`** en el mismo archivo de
    carga que su LSDB de router/network/external. Las LSA tipo 10
    (opaque-area) transportan los datos de TE; el resto del grafo se
    construye a partir de LSA 1, 2 y 5 como de costumbre.

    [:octicons-arrow-right-24: Carga de archivo de texto](../ingestion/text-file.md)

=== "IS-IS — archivo de texto"

    Los atributos de TE vienen directamente de la LSDB de IS-IS cuando usa
    los comandos detallados estándar (por ejemplo, en FRR
    **`show isis database detail`**). No se requiere ningún comando extra
    más allá de su captura normal de IS-IS.

=== "OSPF / IS-IS — BGP-LS"

    **BGP-LS transporta atributos de TE de forma nativa** — grupo
    administrativo, ancho de banda máximo y reservable, ancho de banda no
    reservado, SRLG y la métrica TE por defecto — sin necesidad del truco de
    la opaque LSA. Las actualizaciones de TE se transmiten en vivo hacia la
    vista de monitoreo.

    [:octicons-arrow-right-24: Sesión BGP-LS](../ingestion/bgp-ls.md)

Cuando los datos de TE llegan mediante BGP-LS, la página de monitoreo
muestra los atributos del enlace a medida que llegan las actualizaciones:

![Atributos de enlace TE en la página de monitoreo mediante BGP-LS](../static/te_link_attributes_on_monitoring_page_full_with_bgpls_1.png)

## Filtrar enlaces por atributos de TE

Una vez que un diagrama tiene datos de TE, puede consultar los enlaces por
cualquier atributo de TE usando los operadores de rango `__gt`, `__lt`,
`__gte`, `__lte` — útil para encontrar enlaces que violan (o satisfacen) una
restricción de TE. Con el [SDK de Python](../automation/python-sdk.md):

```python
# Links with TE metric >= 100
edges = graph.edges_list(temetric__gte=100)

# Links with unreserved bandwidth at priority 0 below 1 Gbps
edges = graph.edges_list(unreserved_bw_0__lt=1e9)

# Links between two nodes with max link bandwidth above 10 Gbps
edges = graph.edges_list(src_node="1.1.1.1", dst_node="2.2.2.2", max_link_bw__gt=1e10)
```

El mismo filtrado está disponible mediante la API REST de enlaces del
diagrama.

## Particularidades de IS-IS

TE en IS-IS depende de las **métricas amplias** (Extended IS/IP
Reachability, TLV 22/135) y admite alcanzabilidad **IPv6** (TLV 236). La
compatibilidad de proveedores con los TLV relevantes se resume en la página
[Proveedores compatibles](../reference/supported-vendors.md#is-is-tlv-support).

## Monitoreo de cambios de TE

Cuando un Watcher está conectado, los cambios en los atributos de TE se
capturan como eventos junto con los cambios de costo y adyacencia — consulte
las vistas `te_log` en [ELK / Kibana](../monitoring/elk-kibana.md) y la
página de [IS-IS Watcher](../monitoring/isis-watcher.md).

---

**Relacionado:** [Cómo obtener la topología](../ingestion/index.md) ·
[Visualización y análisis](visualizing.md)

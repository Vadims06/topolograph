# Proveedores compatibles

Topolograph construye un grafo a partir de la Link-State Database de un
solo dispositivo. Use los comandos siguientes para capturar la LSDB y
luego [súbala](../ingestion/text-file.md).

## OSPF (OSPFv2)

| Proveedor | LSA 1 (router) | LSA 2 (network) | LSA 5 (external) | Flags de nodo (ABR/ASBR) | Driver SSH del SDK |
| --- | --- | --- | --- | :---: | :---: |
| Cisco | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ | ✅ |
| Cisco NX-OS | `show ip ospf database router detail` | `show ip ospf database network detail` | `show ip ospf database external detail` | ✅ | ✅ |
| Quagga | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ | ✅ |
| Ruckus | `show ip ospf database link-state router` | `show ip ospf database link-state network` | `show ip ospf database external-link-state` | | ✅ |
| Juniper | `show ospf database router extensive \| no-more` | `show ospf database network extensive \| no-more` | `show ospf database external extensive \| no-more` | ✅ | ✅ |
| Bird | `show ospf state all` | `show ospf state all` | `show ospf state all` | | ✅ |
| Nokia | `show router ospf database type router detail` | `show router ospf database type network detail` | `show router ospf database type external detail` | | ✅ |
| MikroTik | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` | ✅[^mt-flags] | ✅ |
| Huawei | `display ospf lsdb router` | `display ospf lsdb network` | `display ospf lsdb ase` | ✅ | ✅ |
| Palo Alto | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | | ✅ |
| Ubiquiti[^ubnt] | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | | ✅ |
| Allied Telesis | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | | ✅ |
| Extreme | `show ospf lsdb detail lstype router` | `show ospf lsdb detail lstype network` | `show ospf lsdb detail lstype as-external` | | ✅ |
| Ericsson | `show ospf database router detail` | `show ospf database network detail` | `show ospf database external detail` | | ✅ |
| Fortinet | `get router info ospf database router lsa` | `get router info ospf database network lsa` | `get router info ospf database external lsa` | | ✅ |
| FRRouting | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ | ✅ |

[^ubnt]: Aplica a la línea EdgeRouter y a las puertas de enlace UniFi USG
    más antiguas. Las puertas de enlace UniFi más nuevas usan el proyecto
    [FRRouting](https://frrouting.org).

[^mt-flags]: RouterOS 7.18 o más reciente, que imprime el campo `bits=` en
    el volcado de la LSA.

!!! info "Flags de nodo (ABR/ASBR)"
    Los routers que anuncian el bit B (Area Border Router) o E (AS Boundary
    Router) en su Router-LSA se detectan y se muestran en el tooltip del
    nodo al pasar el cursor. La flag también se puede consultar en la API
    de nodos (`?abr=1`, `?asbr=1`). Las mismas flags se reportan en vivo
    desde el [OSPF Watcher](../monitoring/ospf-watcher.md).

!!! tip "Datos opcionales de TE (FRRouting)"
    Agregue `show ip ospf database opaque-area` al mismo archivo para
    obtener datos de ancho de banda, métrica TE y admin group. El grafo se
    sigue construyendo solo con las LSA 1/2/5. Vea
    [Traffic Engineering](../analysis/traffic-engineering.md).

## OSPFv3

| Proveedor | Comando | Red stub | External (redistribuida) |
| --- | --- | :---: | :---: |
| Arista | `show ipv6 ospf database detail` | ✅ | ✅ |
| IP Infusion OcNOS | `show ipv6 ospf database router`, `network`, `external`, `intra-prefix` | ✅ | ✅ |
| Fortinet FortiOS | `get router info6 ospf database router`, `network`, `external`, `intra-prefix` | ✅ | ✅ |
| MikroTik RouterOS | `/routing/ospf/lsa/print detail without-paging where instance=v3` | ✅ | ✅ |

!!! note
    OcNOS y FortiOS necesitan las formas por tipo de LSA: `show ipv6 ospf database` / `get router info6 ospf database` sin tipo muestra solo una tabla de índice, y `intra-prefix` es obligatorio porque OSPFv3 transporta los prefijos únicamente en ese LSA.

## IS-IS

| Proveedor | Comando | Red stub | External (redistribuida) | Flags de nodo (OL/ATT) |
| --- | --- | --- | --- | :---: |
| Cisco | `show isis database detail` | ✅ | Aún no (necesita un ejemplo de LSDB) | ✅ |
| Juniper | `show isis database extensive` | ✅ (necesita un ejemplo de LSDB para confirmar) | Aún no (necesita un ejemplo de LSDB) | ✅ (necesita un ejemplo de LSDB para confirmar) |
| Nokia | `show router isis database detail` | ✅ (necesita un ejemplo de LSDB para confirmar) | Aún no (necesita un ejemplo de LSDB) | ✅ (necesita un ejemplo de LSDB para confirmar) |
| Huawei | `display isis lsdb verbose` | ✅ (necesita un ejemplo de LSDB para confirmar) | Aún no (necesita un ejemplo de LSDB) | ✅ (necesita un ejemplo de LSDB para confirmar) |
| ZTE | `show isis database verbose` | ✅ (necesita un ejemplo de LSDB para confirmar) | Aún no (necesita un ejemplo de LSDB) | ✅ (necesita un ejemplo de LSDB para confirmar) |
| FRRouting | `show isis database detail` | ✅ | Aún no (necesita un ejemplo de LSDB) | ✅ |
| IP Infusion OcNOS | `show isis database verbose` | ✅ | ✅ | ✅ |
| Fortinet FortiOS | `get router info isis database detail` | ✅ | ✅ | ✅ (necesita un ejemplo de LSDB para confirmar) |
| MikroTik RouterOS | `/routing/isis/lsp/print detail without-paging` | ✅ | ✅ | |

!!! info "Flags de nodo (overload / attached)"
    Overload (OL) y attached (ATT) se leen de la columna `ATT/P/OL` de cada
    LSP al subir el archivo de texto, y también se reportan en vivo desde el
    [IS-IS Watcher](../monitoring/isis-watcher.md) (que además deriva
    ABR/ASBR vía BGP-LS).

!!! info "¿Tiene un caso no compatible?"
    Varios escenarios de IS-IS están marcados como "necesita un ejemplo de LSDB" — si puede compartir una base de datos de ejemplo, se puede
    añadir soporte. Abra un issue en el repositorio correspondiente.

## Soporte de TLV de IS-IS { #is-is-tlv-support }

El parser de IS-IS (usado por Topolograph y por el
[IS-IS Watcher](../monitoring/isis-watcher.md)) entiende los siguientes
TLV:

| TLV | # | RFC | Cisco | Juniper | Nokia | FRR | Huawei | ZTE | MikroTik |
| --- | :-: | --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| IS Reachability | 2 | ISO 10589 | ✅ | ✅ | ✅ | ✅ |  | ✅ | ✅ |
| Extended IS Reachability (new) | 22 | RFC 5305 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv4 Internal Reachability (old) | 128 | RFC 1195 | ✅ | ✅ | ✅ | ✅ | ✅ |  | ✅ |
| IPv4 External Reachability (old) | 130 | RFC 1195 |  |  |  |  |  |  |  |
| Extended IPv4 Reachability (new) | 135 | RFC 5305 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv6 Reachability | 236 | RFC 5308 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Se interpretan tanto las métricas **narrow** (estilo antiguo) como las
**wide** (estilo nuevo). Las métricas wide llevan atributos de TE — vea
[Traffic Engineering](../analysis/traffic-engineering.md).

## Atributos de TE por proveedor { #te-attributes-by-vendor }

Qué convierte en atributos de enlace el parser de cada proveedor. Una celda vacía significa que el atributo no se lee de esa salida, aunque el router lo anuncie. Una sesión de [Watcher](../monitoring/isis-watcher.md) o BGP-LS transporta todos los atributos que anuncia el router.

### IS-IS { #te-is-is }

| Atributo de TE | Nombre en la API/SDK | Definido en | FRR | Nokia | ZTE | OcNOS |
| --- | --- | --- | :-: | :-: | :-: | :-: |
| Métrica TE por defecto | `temetric` | RFC 5305 §3.7, sub-TLV 18 | ✅ | ✅ |  | ✅ |
| Grupo administrativo | `admin_group` | RFC 5305 §3.1, sub-TLV 3 | ✅ | ✅ | ✅ |  |
| Ancho de banda máximo del enlace | `max_link_bw` | RFC 5305 §3.4, sub-TLV 9 | ✅ | ✅ | ✅ |  |
| Ancho de banda máximo reservable | `max_rsrv_link_bw` | RFC 5305 §3.5, sub-TLV 10 | ✅ | ✅ | ✅ |  |
| Ancho de banda no reservado (por prioridad) | `unreserved_bw_0` … `unreserved_bw_7` | RFC 5305 §3.6, sub-TLV 11 | ✅ | ✅ | ✅ |  |
| Shared risk link group | `srlg` | RFC 5307 §1.2, TLV 138 | ✅ |  |  |  |
| Dirección de la interfaz / del vecino | `local_ip_address`, `remote_ip_address` | RFC 5305 §3.2, §3.3, sub-TLVs 6 / 8 | ✅ | ✅ | ✅ |  |
| ID local / remoto del enlace | `link_local_id`, `link_remote_id` | RFC 5307 §1.1, sub-TLV 4 |  |  | ✅ |  |

Comandos que muestran los sub-TLV: `show isis database detail` (FRR), `show router isis database detail` (Nokia SR OS), `show isis database verbose` (ZTE, IP Infusion OcNOS). OcNOS muestra los sub-TLV de TE solo con `verbose`, no con `detail`.

!!! note
    FRR muestra el SRLG solo en compilaciones que incluyen [FRRouting/frr#22392](https://github.com/FRRouting/frr/pull/22392).

### OSPF { #te-ospf }

| Atributo de TE | Nombre en la API/SDK | Definido en | FRR | OcNOS |
| --- | --- | --- | :-: | :-: |
| Métrica TE por defecto | `temetric` | RFC 3630 §2.5.5, sub-TLV 5 | ✅ | ✅ |
| Grupo administrativo | `admin_group` | RFC 3630 §2.5.9, sub-TLV 9 | ✅ |  |
| Ancho de banda máximo del enlace | `max_link_bw` | RFC 3630 §2.5.6, sub-TLV 6 | ✅ |  |
| Ancho de banda máximo reservable | `max_rsrv_link_bw` | RFC 3630 §2.5.7, sub-TLV 7 | ✅ |  |
| Ancho de banda no reservado (por prioridad) | `unreserved_bw_0` … `unreserved_bw_7` | RFC 3630 §2.5.8, sub-TLV 8 | ✅ |  |
| Shared risk link group | `srlg` | RFC 4203 §1.3, sub-TLV 16 |  |  |
| Dirección de la interfaz local / remota | `local_ip_address`, `remote_ip_address` | RFC 3630 §2.5.3, §2.5.4, sub-TLVs 3 / 4 | ✅ | ✅ |

Añada `show ip ospf database opaque-area` al mismo archivo de carga. OcNOS muestra la métrica TE como `Admin Metric`.

## RFC compatibles { #supported-rfcs }

RFC implementados en los parsers y los cálculos de Topolograph.

| Protocolo | RFC | Qué lee Topolograph |
| --- | --- | --- |
| OSPFv2 | RFC 2328 | LSA Router (1), Network (2) y AS-External (5) |
| OSPFv2 | RFC 3630 | Atributos de TE de los enlaces, a partir de LSA opaque-area (tipo 10) |
| OSPFv2 | RFC 4203 | Shared risk link group (SRLG), cuando los valores llegan desde un Watcher |
| OSPFv2 | RFC 6987 | Flag de stub router (max-metric) en los nodos |
| OSPFv3 | RFC 5340 | LSA Router, Network, AS-External e Intra-Area-Prefix |
| IS-IS | ISO/IEC 10589 | IS Reachability (TLV 2), bases Level 1 / Level 2, bits overload y attached |
| IS-IS | RFC 1195 | IPv4 Internal Reachability (TLV 128) |
| IS-IS | RFC 5305 | Extended IS e IPv4 Reachability (TLV 22, 135) y sub-TLV de TE |
| IS-IS | RFC 5307 | Shared risk link group (TLV 138) e identificadores local / remoto del enlace |
| IS-IS | RFC 5308 | IPv6 Reachability (TLV 236) |
| MPLS TE | RFC 3209 | Prioridades de setup y holding en la colocación CSPF de túneles LSP |
| BGP | RFC 4271, RFC 4456, RFC 4364 | Selección del mejor camino, route reflection y rutas VPN |
| BGP | RFC 7854, RFC 8671, RFC 9069 | BMP: Adj-RIB-In / Adj-RIB-Out y Loc-RIB |
| BGP | RFC 7432, RFC 9136, RFC 8365, RFC 6514 | EVPN: rutas MAC/IP, Inclusive Multicast, Ethernet Segment e IP Prefix sobre VXLAN |

## Ingesta vía BGP-LS

Además de archivos de texto, la topología OSPF e IS-IS se puede obtener en
vivo mediante **BGP-LS**, usando el Watcher correspondiente. Vea
[Sesión BGP-LS](../ingestion/bgp-ls.md).

---

El esquema de API canónico e interactivo está siempre disponible en
`/api/ui/` en su instancia.

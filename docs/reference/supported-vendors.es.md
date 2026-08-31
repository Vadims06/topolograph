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

## IS-IS

| Proveedor | Comando | Red stub | External (redistribuida) | Flags de nodo (OL/ATT) |
| --- | --- | --- | --- | :---: |
| Cisco | `show isis database detail` | ✅ | Aún no (necesita una LSDB probada) | ✅ |
| Juniper | `show isis database extensive` | ✅ (necesita una LSDB probada para confirmar) | Aún no (necesita una LSDB probada) | ✅ (necesita una LSDB probada para confirmar) |
| Nokia | `show router isis database detail` | ✅ (necesita una LSDB probada para confirmar) | Aún no (necesita una LSDB probada) | ✅ (necesita una LSDB probada para confirmar) |
| Huawei | `display isis lsdb verbose` | ✅ (necesita una LSDB probada para confirmar) | Aún no (necesita una LSDB probada) | ✅ (necesita una LSDB probada para confirmar) |
| ZTE | `show isis database verbose` | ✅ (necesita una LSDB probada para confirmar) | Aún no (necesita una LSDB probada) | ✅ (necesita una LSDB probada para confirmar) |

!!! info "Flags de nodo (overload / attached)"
    Overload (OL) y attached (ATT) se leen de la columna `ATT/P/OL` de cada
    LSP al subir el archivo de texto, y también se reportan en vivo desde el
    [IS-IS Watcher](../monitoring/isis-watcher.md) (que además deriva
    ABR/ASBR vía BGP-LS).

!!! info "¿Tiene un caso no compatible?"
    Varios escenarios de IS-IS están marcados como "necesita una LSDB
    probada" — si puede compartir una base de datos de ejemplo, se puede
    añadir soporte. Abra un issue en el repositorio correspondiente.

## Soporte de TLV de IS-IS { #is-is-tlv-support }

El parser de IS-IS (usado por Topolograph y por el
[IS-IS Watcher](../monitoring/isis-watcher.md)) entiende los siguientes
TLV:

| TLV | # | Cisco | Juniper | Nokia | FRR | Huawei | ZTE |
| --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| IS Reachability | 2 | ✅ | ✅ | ✅ | ✅ | | ✅ |
| Extended IS Reachability (new) | 22 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv4 Internal Reachability (old) | 128 | ✅ | ✅ | ✅ | ✅ | ✅ | |
| IPv4 External Reachability (old) | 130 | | | | | | |
| Extended IPv4 Reachability (new) | 135 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv6 Reachability | 236 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Se interpretan tanto las métricas **narrow** (estilo antiguo) como las
**wide** (estilo nuevo). Las métricas wide llevan atributos de TE — vea
[Traffic Engineering](../analysis/traffic-engineering.md).

## Ingesta vía BGP-LS

Además de archivos de texto, la topología OSPF e IS-IS se puede obtener en
vivo mediante **BGP-LS**, usando el Watcher correspondiente. Vea
[Sesión BGP-LS](../ingestion/bgp-ls.md).

---

El esquema de API canónico e interactivo está siempre disponible en
`/api/ui/` en su instancia.

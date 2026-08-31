# Carga de Archivo de Texto

La forma más simple de introducir una topología en Topolograph: copie la
Base de Datos de Estado de Enlace de **un** router y péguela (o súbala). Sin
agentes, sin túneles, nada que toque la red en vivo.

![Suba un archivo de texto LSDB y construya rutas cortas](../assets/text_file_and_short_paths.gif)

## Por qué basta con un router

OSPF e IS-IS son protocolos de estado de enlace: cada router dentro de un
área/nivel mantiene una copia **idéntica** de la base de datos del área.
Topolograph reconstruye toda la topología a partir de esa única copia — así
que solo necesita recolectarla una vez, desde un dispositivo.

Para ver la red a través de varias áreas, recolecte la salida de un **ABR**
(Area Border Router): contiene la LSDB de todas las áreas a las que se conecta.

## 1. Recolecte la base de datos

Ejecute los comandos de base de datos de LSA/LSP para su plataforma y guarde
la salida en un archivo de texto plano. La matriz completa está a
continuación; consulte
[Proveedores compatibles](../reference/supported-vendors.md) para detalles
de OSPFv3 y TLV de IS-IS.

=== "OSPF (OSPFv2)"

    | Vendor | LSA 1 (router) | LSA 2 (network) | LSA 5 (external) |
    | --- | --- | --- | --- |
    | Cisco | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |
    | Cisco NX-OS | `show ip ospf database router detail` | `show ip ospf database network detail` | `show ip ospf database external detail` |
    | Quagga | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |
    | Ruckus | `show ip ospf database link-state router` | `show ip ospf database link-state network` | `show ip ospf database external-link-state` |
    | Juniper | `show ospf database router extensive \| no-more` | `show ospf database network extensive \| no-more` | `show ospf database external extensive \| no-more` |
    | Bird | `show ospf state all` | `show ospf state all` | `show ospf state all` |
    | Nokia | `show router ospf database type router detail` | `show router ospf database type network detail` | `show router ospf database type external detail` |
    | MikroTik | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` |
    | Huawei | `display ospf lsdb router` | `display ospf lsdb network` | `display ospf lsdb ase` |
    | Palo Alto | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` |
    | Ubiquiti[^ubnt] | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |
    | Allied Telesis | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |
    | Extreme | `show ospf lsdb detail lstype router` | `show ospf lsdb detail lstype network` | `show ospf lsdb detail lstype as-external` |
    | Ericsson | `show ospf database router detail` | `show ospf database network detail` | `show ospf database external detail` |
    | Fortinet | `get router info ospf database router lsa` | `get router info ospf database network lsa` | `get router info ospf database external lsa` |
    | FRRouting | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |

    [^ubnt]: Se aplica a la línea EdgeRouter y a los gateways UniFi USG más
        antiguos. Los gateways UniFi más recientes usan el proyecto
        [FRRouting](https://frrouting.org).

=== "OSPFv3"

    | Vendor | Command |
    | --- | --- |
    | Arista | `show ipv6 ospf database detail` |

=== "IS-IS"

    | Vendor | Database command |
    | --- | --- |
    | Cisco | `show isis database detail` |
    | Juniper | `show isis database extensive` |
    | Nokia | `show router isis database detail` |
    | Huawei | `display isis lsdb verbose` |
    | ZTE | `show isis database verbose` |

Puede colocar las secciones LSA 1 / 2 / 5 (OSPF) en un único archivo —
Topolograph las analiza en conjunto.

!!! tip "Opcional: enlaces más completos con datos de TE"
    Para OSPF en FRRouting, agregue `show ip ospf database opaque-area` al
    mismo archivo para incluir el ancho de banda del enlace, la métrica de TE
    y el grupo administrativo. El grafo se sigue construyendo sin esto.
    Consulte [Traffic Engineering](../analysis/traffic-engineering.md).

## 2. Súbala

1. Abra Topolograph (`http://localhost:8080/` para una
   [instalación local](../getting-started/quickstart-docker.md)).
2. Inicie una carga de topología y pegue o adjunte su archivo de texto.
3. Seleccione el **proveedor** y el **protocolo** (OSPF / IS-IS)
   correspondientes.
4. Envíe. Topolograph analiza la base de datos y renderiza el grafo.

![Subir un archivo de texto LSDB y construir rutas cortas](../assets/text_file_and_short_paths.gif)

El resultado es una **instantánea** — una imagen congelada de la red en el
momento de la captura. Todo análisis se ejecuta contra la instantánea, así
que nada de lo que pruebe afecta a la producción.

## 3. Compare estados a lo largo del tiempo

Suba otra captura más tarde y Topolograph puede **comparar** las dos
instantáneas, resaltando exactamente qué cambió — nodos y enlaces
nuevos/eliminados, cambios de costo y redes que aparecen/desaparecen.
Consulte [Comparación de Estados de Red](../analysis/comparing-states.md).

## Cargar mediante la API en su lugar

Todo lo que puede pegar, también puede `POST`. El
[SDK de Python](../automation/python-sdk.md) envuelve esto — e incluso puede
recolectar la LSDB de sus dispositivos por SSH y subirla en un solo paso:

```bash
topo ingest inventory.yaml --upload --url http://localhost:8080
```

```python
graph = topo.uploader.upload_raw(
    lsdb_text=raw_text,
    vendor="FRR",
    protocol="isis",
)
```

---

**¿Quiere actualizaciones en vivo en lugar de instantáneas?** Transmita la
topología con una sesión de Watcher por [GRE](gre.md) o [BGP-LS](bgp-ls.md).

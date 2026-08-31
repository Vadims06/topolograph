# Topologías Basadas en YAML

Topolograph normalmente construye un grafo a partir de una LSDB de
OSPF/IS-IS — pero desde la **v2.32** también puede construir uno a partir de
una **definición YAML**. Eso significa que puede diseñar una topología
arbitraria desde cero (ni siquiera tiene que ser un dominio de IGP),
mantenerla actualizada mediante la API REST, y ejecutar sobre ella exactamente
el mismo análisis.

!!! abstract "Network Diagram as a Service"
    LSDB ⇄ YAML es intercambiable **en ambos sentidos**. Puede diseñar un
    dominio de IGP desde cero *o* exportar una LSDB cargada a YAML, luego
    agregar enlaces, cambiar costos y volver a comprobar la reacción de la
    red a sus ediciones.

## Un diagrama básico

Un diagrama YAML es simplemente `nodes` y `edges`:

```yaml
nodes:
  10.10.10.1:
    label: Router1
  10.10.10.2:
    label: Router2
edges:
  - src: 10.10.10.1
    dst: 10.10.10.2
    cost: 10
```

Súbalo mediante la API REST:

```python
import requests

yaml_diagram = """
nodes:
  10.10.10.1:
    label: Router1
  10.10.10.2:
    label: Router2
edges:
  - src: 10.10.10.1
    dst: 10.10.10.2
    cost: 10
"""

requests.post(
    'http://<topolograph-host>/api/diagram',
    auth=('', ''),
    json={'yaml_diagram_str': yaml_diagram},
)
```

…o con el [SDK de Python](../automation/python-sdk.md):

```python
from topolograph import Topolograph

topo = Topolograph(url="topolograph-url", token="your-token")
graph = topo.graphs.upload_diagram(yaml_diagram)
print(f"Diagram uploaded: {graph.graph_time}")
```

## Atributos y etiquetas de nodo

- El **nombre del nodo es obligatorio** y debe tener formato de dirección
  IP. Para mostrar algo más amigable, establezca un `label`.
- **Las etiquetas son opcionales.** Adjunte cualquier par `key: value` (los
  valores pueden ser cadenas, números, diccionarios o listas) — por ejemplo
  `location`, `ha_role`, o cualquier cosa que tenga sentido para usted.

Las etiquetas hacen que los nodos sean **consultables**. Dado un grafo de 6
nodos, puede seleccionar, por ejemplo, todos los nodos primarios en DC1:

```python
query_params = {'location': 'dc1', 'ha_role': 'primary'}
r = requests.get(
    f'http://{HOST}:{PORT}/api/diagram/{graph_time}/nodes',
    auth=('', ''),
    params=query_params,
)
# -> [{'ha_role': 'primary', 'id': 1, 'label': '10.10.10.2',
#      'location': 'dc1', 'name': '10.10.10.2', 'size': 15}]
```

## Atributos de enlace

Cada enlace tiene como mínimo un `src`, `dst` y `cost`. Los enlaces también
pueden llevar [atributos de Traffic Engineering](traffic-engineering.md)
(ancho de banda, métrica de TE, grupo administrativo), sobre los cuales
puede luego filtrar mediante la API de enlaces del diagrama.

## Atributos de red

Las subredes que terminan en un nodo viven en una sección de nivel superior
`stub_networks:`. Son metadatos de terminación, exactamente como cuando una
subred se analiza a partir de una LSDB real — no se crea ningún nodo de
grafo para ellas, así que cuentan para la cobertura de respaldo y la
puntuación de red en lugar de contar para el número de nodos. Una subred
anunciada por dos o más nodos se trata como respaldada.

```yaml
stub_networks:
  192.168.1.0/24:
    - node: 10.10.10.1
      cost: 10
      area: 0
    - node: 10.10.10.2
      cost: 20
      area: 0
```

| key | values / format | meaning |
|---|---|---|
| subnet | CIDR, e.g. `192.168.1.0/24` | la clave de cada entrada; su valor es la lista de nodos que la anuncian |
| `node` | node name, must exist in `nodes` | nodo que anuncia la subred |
| `cost` | int | costo desde ese nodo hasta la subred |
| `area` | int | área en la que se anuncia la subred |
| `metric_type` | int | estilo de métrica de IS-IS |
| `isnarrow`, `isextended` | bool | codificación de métrica de IS-IS |

Exportar una topología de vuelta a YAML conserva esta sección, así que un
ciclo LSDB → YAML → LSDB no pierde las subredes.

## Túneles MPLS TE

Un diagrama también puede declarar túneles RSVP-TE/SR-TE en una sección de
nivel superior `lsps:`, junto a `nodes`/`edges`. Topolograph ejecuta la
colocación CSPF sobre ellos (ancho de banda, afinidad, SRLG) y le permite
consultar el resultado, o comprobar si un túnel nuevo hipotético cabría, sin
tocar el grafo.

```yaml
lsps:
  TUN_R1_R3:
    src: 10.10.10.1
    dst: 10.10.10.3
    bandwidth: 2G
```

[:octicons-arrow-right-24: Túneles MPLS TE](mpls-te-tunnels.md)

## Por qué usarlo

- **Pruebe una hipótesis antes de construir** — planifique un nuevo enlace o
  LSP, modélelo en el diagrama YAML y compruebe cómo se reconverge la red.
- **Sirva un diagrama de red** — construya el grafo a partir de nodos y
  enlaces, incluidos metadatos como proveedor, rol del proveedor o rol del
  nodo. Esto es Network Diagram as a Service.

---

**Siguiente:** [Atributos de Traffic Engineering →](traffic-engineering.md)

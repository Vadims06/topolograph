# Topologies basées sur YAML

Topolograph construit généralement un graphe à partir d'une LSDB OSPF/IS-IS
— mais depuis la **v2.32**, il peut aussi en construire un à partir d'une
**définition YAML**. Cela signifie que vous pouvez concevoir une topologie
arbitraire à partir de zéro (elle n'a même pas besoin d'être un domaine
IGP), la maintenir à jour via l'API REST, et exécuter dessus toutes les
mêmes analyses.

!!! abstract "Network Diagram as a Service"
    LSDB ⇄ YAML est interchangeable **dans les deux sens**. Vous pouvez
    concevoir un domaine IGP à partir de zéro *ou* exporter une LSDB
    importée vers YAML, puis ajouter des liens, changer les coûts, et
    revérifier la réaction du réseau à vos modifications.

## Un diagramme de base

Un diagramme YAML n'est constitué que de `nodes` et `edges` :

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

Importez-le via l'API REST :

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

…ou avec le [SDK Python](../automation/python-sdk.md) :

```python
from topolograph import Topolograph

topo = Topolograph(url="topolograph-url", token="your-token")
graph = topo.graphs.upload_diagram(yaml_diagram)
print(f"Diagram uploaded: {graph.graph_time}")
```

## Attributs et étiquettes de nœud

- Un **nom de nœud est obligatoire** et doit être au format adresse IP.
  Pour afficher quelque chose de plus convivial, définissez un `label`.
- Les **étiquettes (tags) sont optionnelles.** Attachez n'importe quelles
  paires `clé: valeur` (les valeurs peuvent être des chaînes, des nombres,
  des dictionnaires ou des listes) — par exemple `location`, `ha_role`, ou
  tout ce qui a du sens pour vous.

Les étiquettes rendent les nœuds **interrogeables**. Sur un graphe de 6
nœuds, vous pouvez par exemple sélectionner tous les nœuds primaires du
DC1 :

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

## Attributs de lien

Chaque lien possède au minimum un `src`, un `dst` et un `cost`. Les liens
peuvent aussi porter des [attributs d'ingénierie de trafic](traffic-engineering.md)
(bande passante, métrique TE, groupe administratif), sur lesquels vous
pouvez ensuite filtrer via l'API des liens de diagramme.

## Attributs de réseau

Les sous-réseaux terminés sur un nœud vivent dans une section de premier
niveau `stub_networks:`. Il s'agit de métadonnées de terminaison, exactement
comme lorsqu'un sous-réseau est analysé depuis une LSDB réelle — aucun
nœud de graphe n'est créé pour eux, ils comptent donc pour la couverture de
secours et le score du réseau plutôt que pour le nombre de nœuds. Un
sous-réseau annoncé par deux nœuds ou plus est considéré comme protégé par
un secours.

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

| clé | valeurs / format | signification |
|---|---|---|
| subnet | CIDR, ex. `192.168.1.0/24` | la clé de chaque entrée ; sa valeur est la liste des nœuds annonceurs |
| `node` | nom de nœud, doit exister dans `nodes` | nœud annonçant le sous-réseau |
| `cost` | entier | coût depuis ce nœud vers le sous-réseau |
| `area` | entier | zone dans laquelle le sous-réseau est annoncé |
| `metric_type` | entier | style de métrique IS-IS |
| `isnarrow`, `isextended` | booléen | encodage de métrique IS-IS |

L'export d'une topologie vers YAML conserve cette section, si bien qu'un
aller-retour LSDB → YAML → LSDB ne perd pas les sous-réseaux.

## Tunnels MPLS TE

Un diagramme peut aussi déclarer des tunnels RSVP-TE/SR-TE dans une section
de premier niveau `lsps:`, à côté de `nodes`/`edges`. Topolograph exécute le
placement CSPF sur ceux-ci (bande passante, affinité, SRLG) et vous permet
d'interroger le résultat, ou de vérifier si un nouveau tunnel hypothétique
tiendrait, sans toucher au graphe.

```yaml
lsps:
  TUN_R1_R3:
    src: 10.10.10.1
    dst: 10.10.10.3
    bandwidth: 2G
```

[:octicons-arrow-right-24: Tunnels MPLS TE](mpls-te-tunnels.md)

## Pourquoi l'utiliser

- **Testez une hypothèse avant de construire** — planifiez un nouveau lien ou
  LSP, modélisez-le dans le diagramme YAML et vérifiez comment le réseau
  reconverge.
- **Servez un diagramme réseau** — construisez le graphe à partir des nœuds et
  des liens, y compris des métadonnées telles que le fournisseur, le rôle du
  fournisseur ou le rôle du nœud. C'est un Network Diagram as a Service.

---

**Suivant :** [Attributs d'ingénierie de trafic →](traffic-engineering.md)

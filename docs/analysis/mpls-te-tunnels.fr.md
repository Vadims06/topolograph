# Tunnels MPLS TE

En complément des [topologies basées sur YAML](yaml-topologies.md) et des
[attributs d'ingénierie de trafic](traffic-engineering.md), un diagramme
peut déclarer des **tunnels MPLS TE** (de style RSVP-TE ou SR-TE) dans une
section de premier niveau `lsps:`. Topolograph exécute dessus un placement
CSPF (Constrained Shortest Path First) — avec les mêmes contraintes de
bande passante/affinité/SRLG qu'un routeur réel, sans aucune signalisation
— et visualise le résultat.

![Tunnels MPLS TE : table des LSP et chemins placés sur le graphe](../static/mpls-lsp-graph-and-table.png)

L'onglet **LSP tunnels** liste chaque chemin avec son statut de placement,
sa raison d'échec, sa bande passante et ses priorités ; sélectionner un
nœud affiche les tunnels qui y entrent, y transitent ou en sortent, et les
chemins placés sont dessinés sur le canevas.

!!! info "Diagrammes YAML uniquement, pour l'instant"
    `lsps:` est disponible sur les diagrammes basés sur YAML. La prise en
    charge des tunnels rapportés en direct par un watcher est prévue pour
    une version ultérieure.

## Un tunnel en YAML

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

## Référence des clés

| clé | niveau | valeurs / format | signification |
|---|---|---|---|
| `lsps` | premier niveau | dict, nom de tunnel → corps | section optionnelle à côté de `nodes`/`edges` |
| `src`, `dst` | tunnel | nom de nœud (format adresse IP) | extrémités du tunnel |
| `metric_type` | tunnel | `igp` (défaut) \| `te` | métrique optimisée par CSPF |
| `bandwidth` | tunnel/chemin | `2G`, `500M`, ou un nombre brut en bps | bande passante requise ; un chemin remplace la valeur par défaut du tunnel |
| `setup_priority` | tunnel/chemin | `0`–`7`, défaut `7` | pool d'admission RSVP-TE (`0` est le plus fort) |
| `hold_priority` | tunnel/chemin | `0`–`7`, par défaut égal à `setup_priority` | pool dans lequel la réservation est maintenue ; ne peut pas être plus faible que la priorité de setup |
| `admin_groups` | tunnel/chemin | dict : `exclude-any` / `include-any` / `include-all` → liste de noms | filtre d'affinité |
| `srlg_exclude` | chemin | liste d'entiers | contrainte SRLG |
| `color` | tunnel | couleur CSS | couleur de mise en évidence sur le canevas |
| `autoroute` | tunnel | booléen, défaut `false` | voir ci-dessous |
| `paths` | tunnel | dict, nom de chemin → corps ; omis = un seul `primary` dynamique | les LSP du tunnel |
| `role` | chemin | `primary` (défaut) \| `secondary` \| `standby` | rôle du chemin |
| `ero` | chemin | liste : `10.10.10.2` (saut souple) ou `{node: ..., hop: strict}` | route explicite |

Un chemin hérite de `bandwidth`, `setup_priority`, `hold_priority` et
`admin_groups` du tunnel lorsqu'il les omet. `srlg_exclude` et `ero` ne
sont **pas** hérités — déclarer `srlg_exclude` au niveau du tunnel n'a
aucun effet, définissez-le sur chaque chemin qui en a besoin.

Les liens déclarent les mêmes attributs TE que ceux couverts sur la
[page Ingénierie de trafic](traffic-engineering.md#what-topolograph-parses)
(`temetric`, `max_rsrv_link_bw`, `admin_group`/affinité, `srlg`,
`unreserved_bw_0`…`unreserved_bw_7`) — pas de nommage distinct pour les
besoins MPLS.

### `autoroute`

Un **LSP signalé ne redirige pas le trafic de lui-même** — cela correspond
au comportement réel de RSVP-TE/SR-TE : sans `autoroute announce` (ou une
route statique explicite pointant vers le tunnel), un tunnel n'est qu'une
bande passante réservée, invisible pour le calcul de chemin de style IGP.
Définissez `autoroute: true` sur un tunnel pour qu'il agisse comme un
raccourci de forwarding dans les requêtes de chemin de bout en bout (voir
`with_lsps` ci-dessous) — l'équivalent réel de l'activation de l'autoroute
sur le headend.

### Priorité de setup et de maintien

`0` est la priorité la plus forte et `7` la plus faible. Si vous omettez
`hold_priority`, elle suit `setup_priority`, comme pour la commande
`priority <setup>` d'un routeur avec la seconde valeur omise.

Un tunnel établi à une priorité forte mais maintenu à une priorité faible
serait préemptable dès sa signalisation, donc cette combinaison est
rejetée : `hold_priority` doit être au moins aussi forte que
`setup_priority` (`setup_priority: 0` avec `hold_priority: 7` est une
erreur de validation, `setup_priority: 7` avec `hold_priority: 0` est
correct).

### Clés (opérationnelles) rejetées

`rro`, `oper_status`, `active_lsp_name`, et toute clé `label_*` sont
**rejetées** dans `lsps:` — elles décrivent un état de signalisation en
direct (Record Route, statut actuel, chemin actif), pas une intention
déclarée, et n'ont de sens qu'une fois qu'un véritable watcher les
rapporte. Une erreur de validation est levée si vous en incluez une.

## Placement CSPF

À chaque sauvegarde, Topolograph place chaque chemin dans l'ordre de
`setup_priority` (convention RSVP-TE : `0` le plus élevé), selon les mêmes
règles qu'appliquerait un routeur réel :

- il filtre les liens qui n'ont pas assez de bande passante dans le pool
  `setup_priority` demandé, ne satisfont pas le filtre d'affinité, ou sont
  dans un SRLG exclu ;
- il exécute le chemin le plus court sur ce qui reste, en respectant tout
  `ero` (un saut `strict` doit être un lien direct depuis le saut
  précédent — le LSP échoue plutôt que d'être discrètement contourné) ;
- il soustrait la bande passante placée de ce pool (et de chaque pool de
  priorité inférieure) avant de placer le chemin suivant.

Le placement ne modifie jamais les attributs TE annoncés
(`unreserved_bw_*`) — la capacité consommée est suivie séparément, si bien
que relancer le placement part toujours des chiffres réellement annoncés.

Les égalités ECMP sont départagées de façon déterministe : le moins de
sauts, puis l'ordre lexicographique des noms de nœuds.

## Lire les résultats de placement

`GET /api/graph/{graph_time}/lsps` et
`GET /api/graph/{graph_time}/lsps/{name}` renvoient le résultat de
placement de chaque chemin aux côtés de sa configuration déclarée :

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

`reason` explique en mots *pourquoi* un chemin non placé a échoué. À ses
côtés, `reason_code` donne la catégorie lisible par machine et
`binding_constraints` nomme ce qui bloque réellement :

| `reason_code` | signification | que faire |
|---|---|---|
| `disconnected` | aucun chemin n'existe même en levant toutes les contraintes | réparer la topologie |
| `constraints_unsatisfiable` | un chemin existe, la demande est trop stricte | relâcher les contraintes dans `binding_constraints` (`bandwidth`, `affinity`, `srlg`) |
| `ero_strict_hop_unreachable` | un saut strict n'a pas de lien depuis le saut précédent | corriger l'`ero` |
| `endpoint_not_found` | `src`/`dst` n'est pas dans le graphe | corriger l'extrémité |

Plusieurs entrées dans `binding_constraints` signifient qu'elles ne
bloquent qu'en combinaison — en lever une seule suffit.

Filtres utiles sur le point de terminaison de liste :

```python
# Which tunnels failed to place, and why
graph.lsps_list(status="unplaced")

# Which tunnels cross a given node or link (pre-maintenance impact check)
graph.lsps_list(via_node="10.10.10.2")
graph.lsps_list(via_edge="10.10.10.1,10.10.10.2")
```

Combien de bande passante TE reste sur un lien, une fois tous les tunnels
placés pris en compte :

```python
graph.edges_list(include=["lsp_left_bw"])
# -> ..., "lsp_left_bw_7": ..., "lsp_reserved_bw": "7Gbps",
#    "lsp_left_bw": "3Gbps", "lsp_bandwidth_usage": "7Gbps/3Gbps"
```

## Chemin CSPF, sans déclarer de tunnel

`cspf_path` répond à la question « quel chemin satisfait ces contraintes,
et à quel coût » — un calcul de chemin le plus court filtré par
contraintes, la même classe de requête qu'un chemin le plus court simple.
Rien n'est créé ni persisté :

```python
result = graph.cspf_path(
    "10.10.10.1", "10.10.10.7",
    bandwidth="5G",
    admin_exclude_any=["red"],
)
# {'path': [...], 'cost': 42, 'reason': ''}
# or, if nothing fits: {'path': [], 'cost': None, 'reason': 'no path ... satisfies the requested constraints: ...'}
```

La réponse tient compte de la bande passante que **les tunnels déjà
déclarés retiennent** : sur une topologie avec une section `lsps:`, la
vérification s'exécute par rapport à ce qu'il reste sur chaque lien après
placement, et non par rapport à la valeur annoncée, si bien que le
résultat ne promet jamais une capacité déjà prise. Les contraintes sont
évaluées par priorité de setup, si bien qu'un lien peut être plein à une
priorité et avoir encore de la place à une priorité plus forte.

Les contraintes d'affinité (`admin_exclude_any`, `admin_include_any`,
`admin_include_all`) correspondent aux **noms** d'affinité sur le lien.
Les topologies importées depuis un réseau en direct annoncent le groupe
administratif sous forme de masque de bits, donc un `include-any`/
`include-all` basé sur les noms sur ces graphes ne correspond à rien et la
réponse est « aucun chemin » — utilisez `exclude-any` ou une topologie YAML
avec des affinités nommées dans ce cas.

## Chemin de bout en bout via les tunnels (`with_lsps`)

Par défaut, `graph.paths.shortest(src, dst)` est un chemin IGP simple —
non affecté par aucun tunnel du graphe, comme le forwarding IP réel sans
autoroute. Passez `with_lsps=True` pour tenir compte des tunnels
`autoroute: true` comme raccourcis de forwarding :

```python
graph.paths.shortest("10.10.10.1", "10.10.10.4")               # plain IGP path
graph.paths.shortest("10.10.10.1", "10.10.10.4", with_lsps=True) # via active autoroute tunnels
```

## Que se passe-t-il si un lien tombe ?

`edge_failure_reaction` prédit l'impact sur l'ensemble du réseau de la
panne d'un ou plusieurs liens — connectivité, et quels liens gagnent ou
perdent du trafic :

```python
graph.paths.edge_failure_reaction([("10.10.10.1", "10.10.10.2")])
# {'isGraphStillConnected': True, 'affectedLinks': {...}, 'disjointedNodes': []}
```

Pour une vue par tunnel de la même question, combinez-le avec
`lsps_list(via_edge=...)` pour voir quels tunnels traversent le lien avant
de vérifier son impact en cas de panne.

---

**Voir aussi :** [Topologies basées sur YAML](yaml-topologies.md) ·
[Attributs d'ingénierie de trafic](traffic-engineering.md) ·
[SDK Python](../automation/python-sdk.md)

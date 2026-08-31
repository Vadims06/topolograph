# API de supervision : événements, chronologie et statut

Cette page est la référence des **champs dérivés** que l'API REST de
Topolograph calcule pour les graphes supervisés : la chronologie des
événements (vagues), le `status` du graphe, et l'`object_status` de
l'événement. Elle explique la signification de chaque valeur calculée.

## Chronologie des événements (vagues)

La **chronologie des événements** regroupe les événements up/down de
nœud/hôte en **vagues** chronologiques afin que vous puissiez raconter un
incident réseau (par exemple : « l'instabilité a commencé à T sur
l'équipement X ; une rafale de flapping de l'équipement Y ; reconvergence
à T+n ») sans parcourir des centaines d'événements bruts. Le regroupement
est calculé côté serveur.

Disponible via l'API REST de Topolograph à :

```
GET /api/events/{graph_time}/adjacency/timeline
    ?last_minutes=<int>       (optionnel)
    ?start_time=<ISO8601>     (optionnel, ex. 2025-06-30T20:00:00Z)
    ?end_time=<ISO8601>       (optionnel)
    ?page=<int>               (optionnel, défaut 1)
    ?per_page=<int>           (optionnel, défaut 20)
```

La liste `waves` est paginée ; la réponse inclut un bloc `pagination`
(`page`, `per_page`, `total`, `total_pages`).

Les événements n'existent que pour les graphes supervisés par un watcher.
La réponse contient **uniquement des résumés de vagues** (pas de tableaux
d'événements imbriqués). Pour récupérer les événements individuels d'une
vague, réinterrogez le point d'accès de l'API Topolograph
`GET /api/events/{graph_time}/adjacency` avec les `start_ts`/`end_ts` de la
vague.

## Comment les vagues sont détectées

Les événements sont placés sur une seule chronologie et découpés en vagues
selon le temps calme entre eux : une nouvelle vague commence quand l'écart
avec l'événement suivant dépasse `gap_multiplier * median_gap_sec`. C'est
la **médiane** de l'écart qui est utilisée (pas la moyenne), afin qu'une
seule longue période de calme ne fausse pas le seuil.

| Champ | Signification |
|-------|---------|
| `gap_multiplier` | Multiplicateur utilisé pour découper les vagues (défaut `5`). |
| `median_gap_sec` | Médiane en secondes entre événements consécutifs (robuste aux rafales). |

## Champs par vague

| Champ | Signification |
|-------|---------|
| `wave_number` | Index séquentiel de la vague, commençant à 1. |
| `start_ts` / `end_ts` | Horodatages ISO 8601 (`...Z`) du premier/dernier événement de la vague. Réutilisables comme `start_time`/`end_time` pour récupérer les événements de la vague. |
| `duration_sec` | Secondes entre le premier et le dernier événement de la vague. |
| `event_count` | Nombre d'événements dans la vague. |
| `distinct_devices` | Nombre d'équipements uniques dans la vague. |
| `trigger_device` | L'équipement du premier événement de la vague. |
| `pattern` | Classification de la vague (voir ci-dessous). |
| `converged` | `true` si chaque équipement resté down dans la vague récupère (un up ultérieur) dans la fenêtre temporelle demandée. Une récupération après `end_time` n'est pas visible, donc une vague peut afficher `converged: false` même si le réseau a récupéré plus tard, hors de la fenêtre. |

## Modèles de vague { #wave-patterns }

`pattern` classe une vague selon ce qui est arrivé à l'état des
équipements. Cela reflète le `status` au niveau du graphe de l'API
Topolograph `GET /api/graph/{graph_time}/status` :

| `pattern` | Signification | Exemple | Statut de graphe associé |
|-----------|---------|---------|----------------------|
| `outage`  | Au moins un équipement reste **down** à la fin de la vague (tombé et non revenu). | `R1 down` (pas de up ultérieur) ; `R1 down, R2 down puis up` (R1 toujours down) | `critical` |
| `flap`    | Tout ce qui est tombé est **revenu up** au sein de la vague. Indépendant du nombre d'équipements : 1 équipement down puis up, ou 100 équipements chacun down puis up, sont tous deux `flap`. | `R1 down puis up` ; `R1..R100 chacun down puis up` | `warning` |
| `up`      | Uniquement des événements **up**, rien n'est tombé dans la vague (une récupération ou une toute nouvelle adjacence). | `R1 up`, `R2 up` | `ok` |

## Exemple de réponse

```json
{
  "graph_time": "10May2025_17h03m00s_7_hosts_ospfwatcher",
  "watcher_name": "demo-watcher",
  "gap_multiplier": 5,
  "median_gap_sec": 10.0,
  "waves": [
    {
      "wave_number": 1,
      "start_ts": "2025-05-10T17:09:24.707000Z",
      "end_ts": "2025-05-10T17:11:27.707000Z",
      "duration_sec": 123.0,
      "event_count": 10,
      "distinct_devices": 6,
      "trigger_device": "10.1.1.3",
      "pattern": "outage",
      "converged": false
    }
  ],
  "pagination": { "page": 1, "per_page": 20, "total": 1, "total_pages": 1 }
}
```

## Statut du graphe

L'API Topolograph `GET /api/graph/{graph_time}/status` renvoie un `status`
global pour le graphe, calculé à partir de sa connectivité et de ses
événements. C'est le pendant, au niveau du graphe entier, du `pattern`
d'une vague :

| `status` | Quand | `pattern` de vague associé |
|----------|------|------------------------|
| `critical` | Le graphe est **déconnecté**, ou un nœud est tombé et n'est **pas** revenu (un down persistant). | `outage` |
| `warning` | Le graphe est connecté, mais un nœud est tombé **puis revenu** (un flap), ou il y a des événements de réseau down ou des changements de coût de lien. | `flap` |
| `ok` | Des événements existent mais sont **uniquement up** (récupérations d'hôte/réseau), ou il n'y a aucun événement et le graphe est connecté. | `up` |
| `no_monitoring_data` | Le graphe n'est pas supervisé par un watcher, il n'a donc aucun événement. | n/a |

`status.details` inclut aussi :

| Champ | Signification |
|-------|---------|
| `is_monitored` | `true` si le graphe est alimenté par un watcher (seuls les graphes supervisés ont des événements). |
| `is_connected` | `true` si le graphe de topologie est entièrement connecté. |
| `up_node_events` / `down_node_events` | Nombre d'événements up / down de nœud depuis la collecte du graphe. |
| `all_host_up_down_events` | Nombre total d'événements up/down d'hôte (y compris ceux récupérés). |
| `network_up_down_events` | Nombre d'événements up/down de réseau (sous-réseau). |
| `adjacency_cost_change_events` | Nombre de changements de coût de lien/adjacence (métrique modifiée, pas un down). |
| `top_unstable_devices` | Top N `{device, event_count}` triés par ordre décroissant (les pires équipements). |

## `object_status` d'événement

Les événements bruts (`/adjacency`, `/networks`) portent un
`object_status` dérivé du changement de coût rapporté par le watcher :

| `object_status` | Signification |
|-----------------|---------|
| `down` | Le coût est passé **à** `-1` (adjacence/réseau tombé). |
| `up` | Le coût est passé **de** `-1` à autre chose (récupéré ou apparu). |
| `changed` | Le coût a changé entre deux valeurs réelles (changement de métrique, pas un down/up). |

Seuls les événements d'hôte `up`/`down` alimentent les
[vagues](#wave-patterns) ; les événements `changed` sont des changements de
coût de lien et sont rapportés séparément sous
`adjacency_cost_change_events`.

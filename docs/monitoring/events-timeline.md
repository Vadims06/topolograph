# Monitoring API: events, timeline & status

This page is the reference for the **derived fields** the Topolograph REST API
computes for monitored graphs: the events timeline (waves), the graph `status`,
and the event `object_status`. It explains what each computed value means.

## Events timeline (waves)

The **events timeline** groups node/host up/down events into chronological
**waves** so you can narrate a network incident (for example: "instability
started at T from device X; a flapping burst from device Y; reconverged at
T+n") without scanning hundreds of raw events. Grouping is computed server-side.

Available via the Topolograph REST API at:

```
GET /api/events/{graph_time}/adjacency/timeline
    ?last_minutes=<int>       (optional)
    ?start_time=<ISO8601>     (optional, e.g. 2025-06-30T20:00:00Z)
    ?end_time=<ISO8601>       (optional)
    ?page=<int>               (optional, default 1)
    ?per_page=<int>           (optional, default 20)
```

The `waves` list is paginated; the response includes a `pagination` block
(`page`, `per_page`, `total`, `total_pages`).

Events exist only for watcher-monitored graphs. The response contains **wave
summaries only** (no nested event arrays). To fetch a wave's individual events,
re-query the Topolograph API endpoint
`GET /api/events/{graph_time}/adjacency` with the wave's `start_ts`/`end_ts`.

## How waves are detected

Events are placed on one chronological timeline and split into waves by the
quiet time between them: a new wave starts when the gap to the next event
exceeds `gap_multiplier * median_gap_sec`. The **median** gap is used (not the
mean) so a single long calm period does not distort the threshold.

| Field | Meaning |
|-------|---------|
| `gap_multiplier` | Multiplier used to split waves (default `5`). |
| `median_gap_sec` | Median seconds between consecutive events (robust to bursts). |

## Per-wave fields

| Field | Meaning |
|-------|---------|
| `wave_number` | Sequential wave index, starting at 1. |
| `start_ts` / `end_ts` | ISO 8601 (`...Z`) timestamps of the first/last event in the wave. Reusable as `start_time`/`end_time` to fetch the wave's events. |
| `duration_sec` | Seconds from the first to the last event of the wave. |
| `event_count` | Number of events in the wave. |
| `distinct_devices` | Number of unique devices in the wave. |
| `trigger_device` | The device of the first event in the wave. |
| `pattern` | Wave classification (see below). |
| `converged` | `true` if every device left down in the wave recovers (a later up) within the queried time window. A recovery after `end_time` is not visible, so a wave can read `converged: false` even if the network later recovered outside the window. |

## Wave patterns

`pattern` classifies a wave by what happened to device state. It mirrors the
graph-level `status` from the Topolograph API
`GET /api/graph/{graph_time}/status`:

| `pattern` | Meaning | Example | Related graph status |
|-----------|---------|---------|----------------------|
| `outage`  | At least one device is left **down** at the end of the wave (fell and did not come back). | `R1 down` (no later up); `R1 down, R2 down then up` (R1 still down) | `critical` |
| `flap`    | Everything that went down came **back up** within the wave. Independent of device count: 1 device down then up, or 100 devices each down then up, are both `flap`. | `R1 down then up`; `R1..R100 each down then up` | `warning` |
| `up`      | Only **up** events, nothing went down in the wave (a recovery or a brand-new adjacency). | `R1 up`, `R2 up` | `ok` |

## Example response

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

## Graph status

The Topolograph API `GET /api/graph/{graph_time}/status` returns an overall
`status` for the graph, computed from its connectivity and events. This is the
graph-wide counterpart of a wave's `pattern`:

| `status` | When | Related wave `pattern` |
|----------|------|------------------------|
| `critical` | The graph is **disconnected**, or a node went down and has **not** come back (a lingering down). | `outage` |
| `warning` | The graph is connected, but a node went **down and back up** (a flap), or there are network-down events or link cost changes. | `flap` |
| `ok` | Events exist but are **up-only** (host/network recoveries), or there are no events at all and the graph is connected. | `up` |
| `no_monitoring_data` | The graph is not watcher-monitored, so it has no events. | n/a |

`status.details` also includes:

| Field | Meaning |
|-------|---------|
| `is_monitored` | `true` if the graph is fed by a watcher (only monitored graphs have events). |
| `is_connected` | `true` if the topology graph is fully connected. |
| `up_node_events` / `down_node_events` | Counts of node up / down events since the graph was collected. |
| `all_host_up_down_events` | Count of all host up/down events (including recovered ones). |
| `network_up_down_events` | Count of network (subnet) up/down events. |
| `adjacency_cost_change_events` | Count of link/adjacency cost changes (metric changed, not a down). |
| `top_unstable_devices` | Top-N `{device, event_count}` sorted descending (the worst offenders). |

## Event `object_status`

Raw events (`/adjacency`, `/networks`) carry an `object_status` derived from the
cost change reported by the watcher:

| `object_status` | Meaning |
|-----------------|---------|
| `down` | Cost changed **to** `-1` (adjacency/network went down). |
| `up` | Cost changed **away from** `-1` (recovered or newly appeared). |
| `changed` | Cost changed between two real values (metric change, not a down/up). |

Only `up`/`down` host events feed the [waves](#wave-patterns); `changed` events
are link cost changes and are reported separately under
`adjacency_cost_change_events`.

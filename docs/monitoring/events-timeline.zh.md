# 监控 API：事件、时间线与状态

本页是 Topolograph REST API 为受监控的图计算的**衍生字段**的参考文档：
事件时间线（波次）、图的 `status`，以及事件的 `object_status`。它解释了
每个计算值的含义。

## 事件时间线（波次）

**事件时间线**将节点/主机的 up/down 事件按时间顺序分组为**波次（wave）**，
以便您能够描述一次网络事故的经过（例如："不稳定始于 T 时刻，源自设备 X；
设备 Y 出现了一阵抖动；在 T+n 时重新收敛"），而无需逐条查看数百条原始事件。
分组计算在服务端完成。

可通过 Topolograph REST API 获取：

```
GET /api/events/{graph_time}/adjacency/timeline
    ?last_minutes=<int>       (optional)
    ?start_time=<ISO8601>     (optional, e.g. 2025-06-30T20:00:00Z)
    ?end_time=<ISO8601>       (optional)
    ?page=<int>               (optional, default 1)
    ?per_page=<int>           (optional, default 20)
```

`waves` 列表是分页的；响应中包含一个 `pagination` 区块
（`page`、`per_page`、`total`、`total_pages`）。

事件只存在于受 watcher 监控的图上。响应**只包含波次摘要**（不包含嵌套的
事件数组）。要获取某个波次的具体事件，需带上该波次的 `start_ts`/`end_ts`
重新查询 Topolograph API 端点 `GET /api/events/{graph_time}/adjacency`。

## 波次是如何检测的

事件被放置在一条统一的时间线上，并根据事件之间的静默时间被切分为多个波次：
当到下一个事件的间隔超过 `gap_multiplier * median_gap_sec` 时，就开始一个新的
波次。使用的是**中位数**间隔（而非平均值），这样单次长时间的平静期就不会
扭曲这个阈值。

| 字段 | 含义 |
|-------|---------|
| `gap_multiplier` | 用于切分波次的乘数（默认 `5`）。 |
| `median_gap_sec` | 连续事件之间间隔秒数的中位数（对突发事件具有鲁棒性）。 |

## 每个波次的字段

| 字段 | 含义 |
|-------|---------|
| `wave_number` | 波次的序号，从 1 开始。 |
| `start_ts` / `end_ts` | 该波次第一个/最后一个事件的 ISO 8601（`...Z`）时间戳。可复用为 `start_time`/`end_time` 来获取该波次的事件。 |
| `duration_sec` | 从该波次第一个事件到最后一个事件的秒数。 |
| `event_count` | 该波次中的事件数量。 |
| `distinct_devices` | 该波次中涉及的唯一设备数量。 |
| `trigger_device` | 该波次中第一个事件所属的设备。 |
| `pattern` | 波次分类（见下文）。 |
| `converged` | 如果该波次中所有下线的设备都在查询的时间窗口内恢复（后续出现了 up），则为 `true`。窗口 `end_time` 之后发生的恢复是不可见的，因此即使网络之后在窗口外恢复了，某个波次也可能显示为 `converged: false`。 |

## 波次模式 { #wave-patterns }

`pattern` 根据设备状态发生的变化对波次进行分类。它对应于 Topolograph API
`GET /api/graph/{graph_time}/status` 返回的图级别 `status`：

| `pattern` | 含义 | 示例 | 相关的图状态 |
|-----------|---------|---------|----------------------|
| `outage`  | 至少有一台设备在该波次结束时仍处于 **down** 状态（下线后未恢复）。 | `R1 down`（之后没有 up）；`R1 down, R2 down then up`（R1 仍处于 down） | `critical` |
| `flap`    | 所有下线的设备都在该波次内**恢复上线**。与设备数量无关：1 台设备 down 后 up，或 100 台设备各自 down 后 up，都属于 `flap`。 | `R1 down then up`；`R1..R100 each down then up` | `warning` |
| `up`      | 只有 **up** 事件，该波次内没有任何设备下线（恢复或全新的邻接关系）。 | `R1 up`、`R2 up` | `ok` |

## 响应示例

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

## 图状态

Topolograph API `GET /api/graph/{graph_time}/status` 会返回该图的整体
`status`，根据其连通性和事件计算得出。这是波次 `pattern` 在图级别的对应物：

| `status` | 何时出现 | 相关的波次 `pattern` |
|----------|------|------------------------|
| `critical` | 图**已断开**，或某个节点下线后**未**恢复（持续处于 down 状态）。 | `outage` |
| `warning` | 图是连通的，但有节点**下线后又上线**了（一次抖动），或者存在网络下线事件或链路开销变化。 | `flap` |
| `ok` | 存在事件，但**只有 up**（主机/网络恢复），或者根本没有任何事件且图是连通的。 | `up` |
| `no_monitoring_data` | 该图未受 watcher 监控，因此没有事件。 | 不适用 |

`status.details` 还包含：

| 字段 | 含义 |
|-------|---------|
| `is_monitored` | 如果该图是由 watcher 提供数据的，则为 `true`（只有受监控的图才有事件）。 |
| `is_connected` | 如果拓扑图是完全连通的，则为 `true`。 |
| `up_node_events` / `down_node_events` | 自该图被采集以来，节点 up / down 事件的计数。 |
| `all_host_up_down_events` | 所有主机 up/down 事件的计数（包括已恢复的）。 |
| `network_up_down_events` | 网络（子网）up/down 事件的计数。 |
| `adjacency_cost_change_events` | 链路/邻接关系开销变化的计数（度量发生变化，而非下线）。 |
| `top_unstable_devices` | 按降序排列的前 N 个 `{device, event_count}`（问题最多的设备）。 |

## 事件的 `object_status`

原始事件（`/adjacency`、`/networks`）携带一个由 watcher 上报的开销变化推导出的
`object_status`：

| `object_status` | 含义 |
|-----------------|---------|
| `down` | 开销**变为** `-1`（邻接关系/网络下线）。 |
| `up` | 开销**从** `-1` **变为其他值**（恢复或新出现）。 |
| `changed` | 开销在两个真实值之间变化（度量变化，不是下线/上线）。 |

只有 `up`/`down` 类的主机事件会计入[波次](#wave-patterns)；`changed` 事件属于
链路开销变化，单独在 `adjacency_cost_change_events` 中报告。

# BMP Watcher

**BMP Watcher** 把 BGP 控制平面引入 Topolograph：对等会话、会话上承载的路由、
VPN 上下文，以及两者的每一次变化。

它是一个被动的 [BMP](https://datatracker.ietf.org/doc/html/rfc7854) 站点。
路由器主动向它发起 TCP 会话并推送自己的 Adj-RIB-In。Watcher 不讲 BGP、不建立
对等关系，也从不主动连接路由器，因此不会给被观测的网络增加任何 BGP 状态。

!!! info "BGP 状态与 IGP 图分开保存"
    BGP 会话是控制平面关系，不是转发链路。BGP 作为独立的图保存，拥有自己的生命
    周期，并*绑定*到 OSPF 与 IS-IS 图上，而绝不会合并进去。即使完全没有 IGP 图，
    BGP 图也能独立工作。

---

## 采集内容

### 地址族

| 地址族 | AFI | SAFI | 事件类型 |
|---|---:|---:|---|
| IPv4 unicast | 1 | 1 | `prefix` |
| IPv6 unicast | 2 | 1 | `prefix` |
| VPNv4 | 1 | 128 | `l3vpn` |
| VPNv6 | 2 | 128 | `l3vpn` |
| EVPN | 25 | 70 | `evpn` |

VPN 路由只有连同它的 Route Distinguisher 才是唯一的，因此 RD 是其身份的一部分。
EVPN 路由根本没有前缀，它由 RFC 7432 的 NLRI 组成部分标识：路由类型、Ethernet
Segment ID、Ethernet Tag、MAC、IP。

### BMP 消息

| BMP 消息 | Topolograph 的处理 |
|---|---|
| Route Monitoring | 构建路由表，以及之后的每一次路由变化 |
| Peer Up | 会话状态，以及对端的 BGP Identifier —— 事件归属的 Router ID |
| Peer Down | 会话拆除，并为该对端承载的每条路由生成 withdraw |
| Initiation / Termination | 采集器会话的生命周期 |
| Statistics Report | 忽略 —— 计数器不是路由状态 |

### 策略流与证据级别

两条 Adj-RIB-In 流分别保存；当 speaker 支持
[RFC 9069](https://datatracker.ietf.org/doc/html/rfc9069) 时，Loc-RIB 流会作为
第三种独立观测保留：

| 流 | Evidence | 含义 |
|---|---|---|
| `pre` / `out-pre` | `pre_policy` | 对端通告了它；本路由器可能已拒绝 |
| `post` / `out-post` | `post_policy` | 本路由器接受了它 —— 候选路径 |
| `loc-rib` | `loc_rib` | 路由器自己的选择 —— 已安装的最优路径 |
| `fib` | `fib` | 存在于转发表中 |

它们绝不会被合并。只在 pre-policy 中出现的路由**永远**不会被报告为已选中或
已安装 —— 这个区分正是两条流存在的理由。

### 是观测记录，不是子网

同一个前缀会按 speaker、按对端、按 path ID、按策略流分别保存。所有副本都会保留，
因为"谁向谁通告了什么"正是监控一张路由表要回答的问题。

---

## 安装采集器

采集器是 [**bmpwatcher**](https://github.com/Vadims06/bmpwatcher) —— 一个 Go 编写
的 BMP 站点，它把最初的表回放与其后的变化区分开。其 README 涵盖了编译、Docker
运行方式，以及 FRR、IOS-XR、Junos 和 SR OS 上的路由器侧 BMP 配置。

同时产生快照与事件流的最小运行方式：

```bash
bmpwatcher \
  --bmp-port=11019 \
  --source-id=pe1 \
  --watcher-name=bmp-dc1 \
  --events=/var/log/bmpwatcher/events.jsonl \
  --topolograph-topology-url=https://topolograph.com/api/watcher/bgp
```

!!! warning "采集器尚未接入鉴权"
    `/api/watcher/bgp` 需要 `Authorization: Bearer sk-...`，而采集器目前不会附加
    该头部 —— 直接推送会收到 `401`。在该能力发布之前，请用
    `--topolograph-topology-file` 将文档写到本地，再自行提交（见下面的 `curl`
    示例）。

在 **Settings → API Tokens → Create token** 获取令牌。工作区由服务端根据令牌解析，
绝不会取自请求体。

---

## 数据接入 API

### `POST /api/watcher/bgp` —— 拓扑快照

采集器在其采集窗口内汇聚整张表，并作为一个文档提交。

```bash
curl -sS -X POST https://topolograph.com/api/watcher/bgp \
  -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data @topolograph-topology.json
```

```json
{
  "time": "2026-08-17T09:12:03Z",
  "user": "bmp-dc1",
  "srcid": "pe1",
  "sesid": "b4f1c8e2",
  "topology": {
    "nodes": [
      {"name": "10.0.0.1", "asn": "65001", "role": "speaker", "router_ip": "10.0.0.1"},
      {"name": "10.0.0.2", "asn": "65002", "role": "peer"}
    ],
    "edges": [
      {"source": "10.0.0.1", "target": "10.0.0.2",
       "peer_ip": "10.0.0.2", "local_ip": "10.0.0.1", "asn": "65002",
       "peer_type": 0, "policies": ["pre", "post"], "families": ["1/1", "1/128"]}
    ],
    "networks": [
      {"subnet": "192.0.2.0/24", "type": "1", "subtype": 1,
       "bmp_source": "10.0.0.1", "peer_ip": "10.0.0.2",
       "policy": ["post"], "path_id": 0, "nexthop": "10.0.0.2",
       "vpn_rd": "65001:100", "rt": "65001:100",
       "labels": [24001], "data": {}}
    ]
  }
}
```

| 字段 | 含义 |
|---|---|
| `time` | 快照时间戳，ISO 8601 —— 同时是过期判定依据 |
| `srcid` | 采集器实例 |
| `sesid` | 采集器的一次*运行*；每次重启都会改变 |
| `nodes[].role` | `speaker` 会上报；`peer` 只是被上报的对象 |
| `edges[]` | 一条 BGP **会话**，而不是一对路由器 |
| `networks[]` | 一条路由**观测记录** |
| `networks[].type` / `subtype` | AFI 为字符串，SAFI 为数字 |
| `networks[].data` | 采集器原始记录，未被提升为字段的属性不会丢失 |

**响应**

```json
{"graph_time": "17Aug2026_09h12m03s_6_hosts", "checkpoint": false, "routes": 1428}
```

`graph_time` 是下文所有读取接口使用的公开标识符，格式与 IGP 图一致。

**顺序与重发。** `sesid` 在采集器启动时生成 —— 正是 speaker 重新回放路由表的时刻。
在同一个 `sesid` 内 `time` 最新者胜出；更旧或相等的会以 `400 stale snapshot`
拒绝。相同 `sesid` 下的周期性全量重发被视为**对账检查点**而不是新图：返回
`checkpoint: true`，它证明在安静的网络中数据源仍然存活，并在当前视图出现漂移时
予以纠正。新的 `sesid` 会取代上一次运行。

所有 Route Target 都从 `data.base_attrs.ext_community_list` 提取，而不仅取被提升
的 `rt` 字段 —— 带多个 RT 的路由按其中任意一个查询都能命中。

### `POST /api/watcher/bgp/events` —— 变化流

接受单个事件对象或事件列表。

```bash
curl -sS -X POST https://topolograph.com/api/watcher/bgp/events \
  -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '[{
        "srcid": "pe1", "sesid": "b4f1c8e2", "seq": 41,
        "watcher_time": "2026-08-17T09:14:11Z",
        "event_name": "prefix", "event_status": "withdraw",
        "event_object": "192.0.2.0/24", "event_detected_by": "10.0.0.2",
        "bmp_source": "10.0.0.1", "policy": "post",
        "afi": 1, "safi": 1, "prefix": "192.0.2.0", "prefix_len": 24,
        "family_data": {"peer_ip": "10.0.0.2"}
      }]'
```

| 字段 | 含义 |
|---|---|
| `event_name` | `prefix`、`l3vpn`、`evpn`、`peer` |
| `event_status` | 路由为 `add`、`change`、`withdraw`；对端为 `up`、`down` |
| `event_detected_by` | 变化所涉及的路由器 |
| `bmp_source` | 上报该变化的 speaker —— 在任何反射会话上都是另一台路由器 |
| `seq` | 在 `sesid` 内单调递增；用于精确去重和缺口检测 |
| `watcher_time` | 采集器时钟 —— 用于排序 |
| `bmp_timestamp` | 路由器时钟 —— 仅用于关联，不用于排序 |
| `replay_suspect` | 可能是回放的尾部，而非实时变化 |

```json
{"accepted": 1, "duplicates": 0}
```

`(srcid, sesid)` 与已存快照不匹配的事件会被拒绝 ——
**请先提交拓扑，再启动事件流**。重复的 `seq` 计为重复并丢弃；`seq` 出现缺口会
记录为消息丢失。

对端 up/down 事件仅用于展示。采集器已经为掉线对端承载的每个前缀发出常规
withdraw，因此对端事件本身绝不会改变路由状态。

### `POST /api/watcher/vrfs` —— VRF 清单

Route Distinguisher 标识 VPN 路由，但只有设备知道 VRF 的*名称*及其导入/导出
Route Target。提交清单后即可按 VRF 名称而非 RD 检索。

```bash
curl -sS -X POST https://topolograph.com/api/watcher/vrfs \
  -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
        "router_id": "10.0.0.1",
        "observed_at": "2026-08-17T09:10:00Z",
        "vrfs": [{
          "name": "Red",
          "families": [{
            "afi": "ipv4", "safi": "unicast",
            "route_distinguisher": "65001:100",
            "import_route_targets": ["65001:100", "65001:999"],
            "export_route_targets": ["65001:100"]
          }]
        }]
      }'
```

每次观测都带自己的时间戳保存，而不是覆盖上一次，因此较早的图仍然可以还原当时的
VRF 状态。唯一性为 `(工作区, router_id, rd)`；内容未变的重发不会写入。

---

## 与 IGP 图的绑定

每次 BGP 保存**以及**每次 IGP 保存之后，Topolograph 都会重新评估某个 BGP 图属于
哪些 OSPF 或 IS-IS 图。候选图按 Router ID 重合度以贪心集合覆盖排序，因此跨越两个
IGP 域的 BGP 图会同时绑定到两者。

| 状态 | 含义 |
|---|---|
| `bound` | Router ID 重合度 ≥ 80%，且无歧义 |
| `needs_mapping` | 低于阈值，或两个候选并列 —— 等待确认 |

Router ID 重合是**证据，而不是硬性要求**。BGP Router ID 与 OSPF Router ID 通常
一致，但 Topolograph 从不强制：有歧义的结果会保留下来由你确认。

```bash
# 某个 BGP 图绑定到了什么
curl -sS ".../api/bgp-graph/17Aug2026_09h12m03s_6_hosts/bindings" -H "Authorization: Bearer $T"

# 手工确认绑定
curl -sS -X PUT ".../api/bgp-graph/<bgp_graph_time>/<igp_graph_time>/binding" -H "Authorization: Bearer $T"

# 删除绑定
curl -sS -X DELETE ".../api/bgp-graph/<bgp_graph_time>/<igp_graph_time>/binding" -H "Authorization: Bearer $T"
```

!!! note "IS-IS 需要真实的 Router ID"
    IS-IS 节点在内部由解析器生成的伪 Router ID 命名，这个地址在网络中并不存在。
    只有设备自己通告的 **TE Router ID** 才算身份。不通告 TE Router ID 的设备对
    重合度没有贡献 —— 这是诚实的结果，而不是缺陷。请在设备上启用 TE，或在
    **主机名映射**页面手工填写 Router ID；之后它会像主机名一样迁移到后续的图。

---

## 数据读取

### 图、节点与会话

```bash
GET /api/bgp-graphs?page=1&per_page=50
GET /api/bgp-graph/{bgp_graph_time}
GET /api/bgp-graph/{bgp_graph_time}/nodes?role=rr&asn=65001
GET /api/bgp-graph/{bgp_graph_time}/sessions?igp_relation=inter-domain&bgp_session_type=ebgp
```

绑定关系确定后，每条会话都会被分类：

| `igp_relation` | 含义 |
|---|---|
| `intra-domain` | 两端位于同一个已绑定的 IGP 图 |
| `inter-domain` | 两端位于两个不同的已绑定 IGP 图 |
| `external` | 至少一端不属于任何已绑定的图 |

`bgp_session_type` 为 `ibgp` 或 `ebgp`，由会话 ASN 与 speaker 自身 ASN 比较得出，
而不是取自 `AS_PATH[0]` —— 后者在反射路由上会产生误导。

### 路由检索

```bash
GET /api/bgp-graph/{bgp_graph_time}/routes?prefix=192.0.2.0/24
GET /api/bgp-graph/{bgp_graph_time}/node/{router_id}/routes?evidence=loc_rib
```

| 查询参数 | 行为 |
|---|---|
| `prefix=192.0.2.0/24` | 按完整前缀精确匹配 |
| `prefix=192.0.2.5` | 包含匹配 —— 覆盖该地址的所有路由 |
| `prefix=192.0.2.0/24&lpm=1` | 最长前缀匹配，返回一行 |
| `afi` / `safi` | 数字形式的地址族 |
| `rd` | Route Distinguisher |
| `vrf` | VRF 名称，通过清单解析为其 RD |
| `rt` | 路由上的任意 Route Target |
| `policy` / `evidence` | 原始流，或 `pre_policy` / `post_policy` / `loc_rib` / `fib` |
| `as_path_contains` | 在 AS_PATH 任意位置做子串匹配 |
| `community` / `large_community` / `extended_community` | community 检索 |
| `origin`、`local_pref`、`med`、`originator_id`、`label` | 属性过滤 |
| `peer_ip`、`nexthop`、`bmp_source` | 谁通告的，以及如何到达 |
| `page`、`per_page` | 分页（`per_page` 上限 500） |

每条路由都携带 VRF/RD/RT、AFI/SAFI、策略与 evidence、path ID、community、
next hop、标签和 origin。

### 历史与比较

```bash
# 当前的表状态，或某一时刻的状态
GET /api/bgp-graph/{bgp_graph_time}/routes/state
GET /api/bgp-graph/{bgp_graph_time}/routes/state?at=2026-08-17T09:20:00Z

# 两个时刻之间发生了什么变化
GET /api/bgp-graph/{bgp_graph_time}/routes/compare?t0=...&t1=...

# 事件流，以及监控时间线的泳道
GET /api/bgp-graph/{bgp_graph_time}/events?last_minutes=60&event_name=peer
GET /api/bgp-graph/{bgp_graph_time}/events/timeline
```

不带 `at` 的 `state` 读取持续维护的当前视图，代价与返回结果规模相当，而不是重放
整个事件日志。显式的 `at` 会从快照基线重放增量直到该时刻。时间边界两端均为闭区间。

`compare` 为每处变化返回一行：`added`、`withdrawn` 或带前后状态的 `changed`。

在监控时间线上，`bgp_peer` 为每次会话 up/down 生成一个标记 —— 数量少，且每次抖动
都重要；`bgp_route` 则做聚簇，因此一阵路由抖动只呈现为一个带计数的标记，而不是
成千上万个点。

### Route lookup

Route lookup 回答的是"这台路由器对这个目的地实际会怎么做"，而不是纯粹的拓扑 SPF。

```bash
GET /api/graph/{graph_time}/route-lookup/{start_node}?destination=192.0.2.5&vrf=Red&with_lsps=1
```

```json
{
  "prefix": "192.0.2.0/24",
  "start_node": "10.0.0.1",
  "route_source": "BGP",
  "admin_distance": 200,
  "nexthop": "10.0.0.9",
  "resolution_chain": ["192.0.2.0/24", "10.0.0.9/32"],
  "path_segments": [{"domain": "17Aug2026_09h05m00s_6_hosts",
                     "path": ["10.0.0.1", "10.0.0.4", "10.0.0.9"]}],
  "warning": null
}
```

决策顺序是刻意设计的：

1. 在选定的表或 VRF 内做**最长前缀匹配**。
2. **BGP 最优路径选择** —— 每个前缀一条路径，依据 LOCAL_PREF、AS_PATH 长度、
   ORIGIN 和 MED，在任何跨协议比较之前完成。Loc-RIB 观测直接结束比较：那就是
   路由器自己的选择。
3. 在不同协议的存活候选之间比较**管理距离**。
4. **递归 next hop 解析**，带环路与深度保护。
5. 到该 next hop 的 **IGP SPF/CSPF 传输**，可选地经由合适的 LSP 捷径。

| 协议 | AD |
|---|---:|
| connected | 0 |
| static | 1 |
| eBGP | 20 |
| OSPF | 110 |
| IS-IS | 115 |
| iBGP | 200 |

管理距离属于**路由**，而不属于拓扑边。OSPF、IS-IS 与 BGP 的度量值从不互相比较 ——
度量只在其所属协议内部有意义。iBGP 还是 eBGP 由学到该路由的会话决定，而不是由
`AS_PATH[0]` 决定。

候选路由被限定在起始节点实际能看到的范围内：它自己上报的表，加上它直连会话邻居
的表。不运行 BGP 的路由器不会继承任何东西。

---

## 保留策略

Topolograph **按数据源**（`srcid`）保留最近的若干 BGP 图，因此运行两个采集器的
部署会各自保留完整的窗口。当某个 epoch 移出窗口时，它的路由和绑定一并删除。
相同 `sesid` 下的周期性重发属于检查点，不占用窗口。

---

## 当前限制

- 采集器尚未附加 API 令牌；暂时请用 `curl` 提交快照。
- 每个 BMP speaker 运行一个采集器并设置 `--source-id`。多个 speaker 汇入一个
  采集器会使它们的观测混在一起。
- EVPN 路由会被采集和保存，但路由表与 route lookup 面向前缀设计；EVPN 尚不是
  一等检索对象。
- 合法出现在两个已绑定 IGP 域中的 Router ID，在会话分类时只会归属其中之一。

---

## 参见

- [bmpwatcher on GitHub](https://github.com/Vadims06/bmpwatcher)
- [OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)
- [事件、时间线与状态](events-timeline.md)
- [BGP-LS 会话](../ingestion/bgp-ls.md) —— BGP-LS 承载的是 *IGP* 拓扑，与本页
  讨论的 BGP 路由状态是不同的主题

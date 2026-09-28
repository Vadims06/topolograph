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
| Peer Up | 会话状态，以及对端的 BGP Identifier - 事件归属的 Router ID |
| Peer Down | 会话拆除，并为该对端承载的每条路由生成 withdraw |
| Initiation / Termination | 采集器会话的生命周期 |
| Statistics Report | 忽略 - 计数器不是路由状态 |

### 策略流与证据级别

两条 Adj-RIB-In 流分别保存；当 speaker 支持
[RFC 9069](https://datatracker.ietf.org/doc/html/rfc9069) 时，Loc-RIB 流会作为
第三种独立观测保留：

| 流 | Evidence | 含义 |
|---|---|---|
| `pre` / `out-pre` | `pre_policy` | 对端通告了它；本路由器可能已拒绝 |
| `post` / `out-post` | `post_policy` | 本路由器接受了它 - 候选路径 |
| `loc-rib` | `loc_rib` | 路由器自己的选择 - 已安装的最优路径 |
| `fib` | `fib` | 存在于转发表中 |

它们绝不会被合并。只在 pre-policy 中出现的路由**永远**不会被报告为已选中或
已安装 - 这个区分正是两条流存在的理由。

---

## 安装采集器

无需真实网络即可试用：运行 bmpwatcher 仓库中的 containerlab 实验拓扑 [13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp)。

采集器是 [**bmpwatcher**](https://github.com/Vadims06/bmpwatcher)，以 Docker 镜像
`vadims06/bmpwatcher:latest` 发布：一个被动的 BMP 站，路由器通过 TCP 11019 连接它，它从不主动连接路由器。
它把初始表导出与之后的变化分开。其 README 介绍了 FRR、IOS-XR、Junos 和 SR OS 路由器侧的 BMP 配置。

你需要一个 Topolograph 账号：在 topolograph.com 注册，或者在自托管实例上用其 `.env` 中设置的用户登录
（`TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `TOPOLOGRAPH_WEB_API_PASSWORD`）。
创建 API 令牌：**API → Token → Create Token**。工作区由服务器根据令牌确定，从不取自请求体。

### 使用 Docker Compose 运行

bmpwatcher 仓库的 compose 文件同时运行采集器和 Fluent Bit 事件发送器：

```bash
git clone https://github.com/Vadims06/bmpwatcher.git && cd bmpwatcher
cp .env.example .env
docker compose --profile collector up -d
```

在 `.env` 中设置：

- `TOPOLOGRAPH_HOST`：Docker 主机的 IP 地址，不要用 `localhost`，因为 Topolograph 和 BMP Watcher 运行在各自的容器网络中；公共实例填 `topolograph.com`。
- `TOPOLOGRAPH_PORT`：默认 `8080`，topolograph.com 用 `443`。
- `WEBHOOK_TLS_ON`：自托管 Topolograph 为 `off`，topolograph.com 为 `on`。
- `TOPOLOGRAPH_API_TOKEN`：`sk-...` 令牌。
- `SOURCE_ID`：该采集器在 Topolograph 中的名称，例如 `dc1-rr`。保持不变：用同一名称重建的容器会把数据保存在一起。
- `BMPWATCHER_LOG_DIR`：采集器写入文件的目录，默认 `/var/log/bmpwatcher`。

用同一 profile 停止：`docker compose --profile collector down`。让 Docker 开机自启（`systemctl enable docker`）：容器会在崩溃和重启后恢复。

每台路由器导出完自己的表后，第一个快照才会发出：大约在其路由停止到达 30 秒后，最迟在第一条路由到达 5 分钟后。检查是否已发送：

```bash
docker logs bmpwatcher 2>&1 | grep 'topology posted'
```

### EVPN：第一批消息

*需要 Topolograph v2.73 及以上、BMP Watcher v1.1.0 及以上。EVPN 导出已在 FRR 上验证。*

EVPN 问题由你的 OSPF 或 IS-IS 图回答，因此 Topolograph 需要一张 Router ID 与 BGP
speaker 一致的图。

1. **准备 IGP 图。** 自己的网络：上传其 LSDB，或运行
   [OSPF Watcher](ospf-watcher.md) / [IS-IS Watcher](isis-watcher.md)。
   [13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp) 实验拓扑：其 OSPF underlay 就是 Topolograph 在每个账户
   首次登录时创建的 13 台路由器演示图；IS-IS 则将
   [demo_isis_LSDB.txt](https://github.com/Vadims06/topolograph/blob/master/demo_isis_LSDB.txt) 作为 FRR IS-IS 上传。
2. **在 route reflector 上启用 BMP**：它们持有所有 leaf 的 EVPN 路由，而 leaf
   只导出自己学到的路由。FRR 以模块方式加载 BMP，因此需在 `bgpd_options` 中加入
   `-M bmp` 并重启 FRR：

```
# /etc/frr/daemons
bgpd_options="   --daemon -M bmp -A 127.0.0.1"
```

```
router bgp 65000
 bmp targets topolograph
  bmp connect 198.51.100.10 port 11019 min-retry 1000 max-retry 2000
  bmp monitor l2vpn evpn pre-policy
  bmp monitor l2vpn evpn post-policy
```

在 containerlab 中，请编辑实验拓扑的 `daemons` 文件并重新部署：在运行中的容器里重启 FRR
会断开其实验链路。`bmp connect` 填写路由器可通过 TCP 11019 访问的采集器主机地址；在
containerlab 中即实验管理网络的网关（`docker network inspect <mgmt-network>`）。

3. **按上文启动采集器。**
4. **在 IGP 图上检查结果**：`protocols` 中包含 `bgp` 的图、它的 VNI 与 VRF，以及某个
   VNI 的 leaf。

```bash
TOPOLOGRAPH_URL=http://<host-ip>:8080   # 公共实例使用 https://topolograph.com
curl -sS "$TOPOLOGRAPH_URL/api/graph/?protocol=bgp" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
curl -sS "$TOPOLOGRAPH_URL/api/graph/<graph_time>/vpns" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
curl -sS "$TOPOLOGRAPH_URL/api/graph/<graph_time>/nodes?protocol=bgp&vni=<vni>" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
```

`?protocol=bgp` 返回空列表表示 BGP 图尚未绑定：请检查
`GET /api/bgp-graph/<bgp_graph_time>/bindings`。初始路由表随快照到达，事件流只携带
之后的变化。

每个账户都有一张演示 BGP 图，采自 13-hosts-demo-bgp 实验拓扑，
并绑定到同一张演示图，因此该图上的答案也包含演示路由。

---

## 与 IGP 图的绑定

每次 BGP 保存**以及**每次 IGP 保存之后，Topolograph 都会重新评估某个 BGP 图属于
哪些 OSPF 或 IS-IS 图。候选图按 Router ID 重合度以贪心集合覆盖排序，因此跨越两个
IGP 域的 BGP 图会同时绑定到两者。

| 状态 | 含义 |
|---|---|
| `bound` | Router ID 重合度 ≥ 80%，且无歧义 |
| `needs_mapping` | 低于阈值，或两个候选并列 - 等待确认 |

BGP 图首先绑定到其自身时间点生效的 IGP 图：即不晚于该 BGP 图的最新一张。
之后拍摄的 IGP 快照，只要该 BGP 图仍是其来源的最新图，并且快照中仍保留首次匹配到的
路由器，也会被绑定。在 IGP 快照之后加入的路由器，通过其 OSPF 邻接事件计入。

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
    重合度没有贡献 - 这是诚实的结果，而不是缺陷。请在设备上启用 TE，或在
    **主机名映射**页面手工填写 Router ID；之后它会像主机名一样迁移到后续的图。

---

## 查询 BGP 数据

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
而不是取自 `AS_PATH[0]` - 后者在反射路由上会产生误导。

### 路由检索

```bash
GET /api/bgp-graph/{bgp_graph_time}/routes?prefix=192.0.2.0/24
GET /api/bgp-graph/{bgp_graph_time}/node/{router_id}/routes?evidence=loc_rib
```

| 查询参数 | 行为 |
|---|---|
| `prefix=192.0.2.0/24` | 按完整前缀精确匹配 |
| `prefix=192.0.2.5` | 包含匹配：覆盖该地址的所有路由，最长前缀在前 |
| `mac`、`vni` | 仅 EVPN，见 [EVPN](#evpn) |
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

在监控时间线上，`bgp_peer` 为每次会话 up/down 生成一个标记 - 数量少，且每次抖动
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
2. **BGP 最优路径选择** - 每个前缀一条路径，依据 LOCAL_PREF、AS_PATH 长度、
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

管理距离属于**路由**，而不属于拓扑边。OSPF、IS-IS 与 BGP 的度量值从不互相比较 -
度量只在其所属协议内部有意义。iBGP 还是 eBGP 由学到该路由的会话决定，而不是由
`AS_PATH[0]` 决定。

候选路由被限定在起始节点实际能看到的范围内：它自己上报的表，加上它直连会话邻居
的表。不运行 BGP 的路由器不会继承任何东西。

## EVPN

*需要 Topolograph v2.73 及以上、BMP Watcher v1.1.0 及以上。*

基于 VXLAN 的 BGP EVPN（AFI 25 / SAFI 70）从 route reflector 的 BMP 数据流中读取。
所有 EVPN 问题都针对你的 OSPF 或 IS-IS 图提出：由绑定到它的 BGP 图回答，每个 VTEP
都解析为拥有该地址的路由器，因此到主机的路径终止于其后面的 leaf。

### 路由类型

| 路由类型 | RFC | 用途 |
|---|---|---|
| 1 Ethernet Auto-Discovery | [RFC 7432](https://datatracker.ietf.org/doc/html/rfc7432) | 存储并可搜索 |
| 2 MAC/IP Advertisement | RFC 7432 | 主机位置：MAC、IP、VNI、VTEP、ESI；MAC 迁移 |
| 3 Inclusive Multicast Ethernet Tag | RFC 7432、[RFC 6514](https://datatracker.ietf.org/doc/html/rfc6514) | 哪些 leaf 是某个 VNI 的 VTEP（VNI 取自 PMSI Tunnel 属性） |
| 4 Ethernet Segment | RFC 7432 | 存储并可搜索 |
| 5 IP Prefix | [RFC 9136](https://datatracker.ietf.org/doc/html/rfc9136) | VRF 的子网及其 L3VNI |

### 路由属性

EVPN 路由带有常规的 RD、route target、next hop 和 community，另有一个 `evpn` 对象：

| 字段 | 含义 |
|---|---|
| `route_type` | 1 到 5 |
| `mac` | 主机 MAC（RT-2） |
| `ip`、`ip_len` | 主机 IP（RT-2），前缀及其长度（RT-5），发起路由器（RT-3、RT-4） |
| `vni` | L2VNI（RT-2、RT-3） |
| `l3vni` | VRF 的 L3VNI（RT-5，以及 symmetric IRB 下的 RT-2） |
| `esi` | Ethernet Segment ID；全零表示单归属主机 |
| `eth_tag` | Ethernet Tag ID |
| `vtep` | VTEP：RT-3 与 RT-4 为发起路由器，其余为 next hop |
| `mm_seq` | MAC Mobility 序列号（[RFC 7432 §15](https://datatracker.ietf.org/doc/html/rfc7432#section-15)） |

RT-2 与 RT-5 同时填写 `prefix`（主机地址 /32 或 /128，或 RT-5 前缀），因此
`prefix=` 能像查找其他路由一样找到 EVPN 主机和子网。

```json
{
  "afi": 25, "safi": 70, "rd": "1:123.123.31.31:5",
  "route_targets": ["65000:1020"], "nexthop": "123.123.31.31",
  "evpn": {"route_type": 2, "mac": "00:c1:ab:00:00:03", "ip": null, "ip_len": null,
           "vni": 1020, "l3vni": null, "esi": "00:00:00:00:00:00:00:00:00:00",
           "eth_tag": 0, "vtep": "123.123.31.31", "mm_seq": null}
}
```

### 能回答的问题

所有问题都针对 IGP 图（`{graph_time}`）提出，无需 BGP 图时间。

| 问题 | 请求 |
|---|---|
| fabric 中有哪些 VNI 和 VRF？ | `GET /api/graph/{graph_time}/vpns` |
| 某台路由器看到哪些 VPN？ | `GET /api/graph/{graph_time}/node/{router_id}/vpns` |
| 哪些 leaf 承载 VNI 1020 或 VRF tenant1？ | `GET /api/graph/{graph_time}/nodes?protocol=bgp&vni=1020` (或 `vrf=tenant1`) |
| 主机在哪里：leaf、VNI、VRF、MAC？ | `GET /api/graph/{graph_time}/routes?prefix=10.10.20.13` 或 `?mac=00:c1:ab:00:00:03` |
| 主机是否多归属？ | 同一请求：多个 VTEP 共享同一个非零 `esi` |
| 某个 VRF 路由哪些前缀？ | `GET /api/graph/{graph_time}/routes?vrf=tenant1` |
| 某个 leaf 上某 VNI 有什么？ | `GET /api/graph/{graph_time}/node/{router_id}/routes?vni=1010` |
| MAC 是否迁移过，从哪个 leaf 到哪个，何时？ | `GET /api/events/{graph_time}/routes?mac=00:c1:ab:00:00:01&last_minutes=60` |
| underlay 如何到达某个 VNI 的所有 VTEP？ | `GET /api/graph/{graph_time}/path/{node_a}/{vtep1},{vtep2}` |

`routes` 还接受 `at=`（过去的某个时刻），以及 `vtep=`、`rt=`、`rd=`、`page`、
`per_page`。在事件历史中，MAC 出现在新 VTEP 上的那一行带有 `moved_from_vtep`。
同一 MAC 由多个 VTEP 以同一 ESI 通告属于多归属，而不是迁移。

VPN 行在 VRF 清单知道名称时按 VRF 名称分组，否则按 route target 分组；EVPN 的
bridge domain 每个 L2VNI 一行：

```json
{"name": null, "vni": 1020, "l3vni": 5000,
 "route_targets": ["65000:1020", "65000:5000"],
 "route_distinguishers": ["1:123.123.30.30:5", "1:123.123.31.31:5"],
 "prefix_count": 4}
```

在界面中，同样的答案位于 BGP / VPN 路径表单，以及 Graph table 的 BGP Routes，
其中上面每个字段都有对应的列。基于演示数据的逐步说明见 [BGP how-to](https://topolograph.com/how-to/bgp#evpn)，
采集这些数据的实验拓扑见 [containerlab/13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp)。

---

## 当前限制

- EVPN 假定 VNI 在整个 fabric 内全局一致：不支持本地有效的 VNI（RFC 8365）。
- Ethernet Segment 的 designated forwarder 由 leaf 自己选举，BMP 不携带这一信息。
- 合法出现在两个已绑定 IGP 域中的 Router ID，在会话分类时只会归属其中之一。

---

## 参见

- [bmpwatcher on GitHub](https://github.com/Vadims06/bmpwatcher)
- [OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)
- [事件、时间线与状态](events-timeline.md)
- [BGP-LS 会话](../ingestion/bgp-ls.md) - BGP-LS 承载的是 *IGP* 拓扑，与本页
  讨论的 BGP 路由状态是不同的主题

# OSPF Watcher

**OSPF Watcher** 是一款用于监控 OSPF 拓扑变化的工具。它通过
[GRE 邻接关系](../ingestion/gre.md)或 [BGP-LS](../ingestion/bgp-ls.md)被动监听
OSPF 控制平面——记录每一次变化，并/或（通过 Logstash 或 Fluent Bit）将其导出到
**ELK**、**Zabbix**、**WebHooks**，以及 **Topolograph** 监控仪表盘。一切都以
容器形式提供，因此启动速度很快。

[:simple-github: vadims06/ospfwatcher](https://github.com/Vadims06/ospfwatcher){ .md-button }

![带有 XDP 规则的 OSPF Watcher + Topolograph 架构](../assets/ospfwatcher_architecture.png)

## 检测到的事件

- OSPF 邻居邻接关系 **Up/Down**
- OSPF 链路**开销变化**
- OSPF 网络的**出现/消失**
- OSPF **TE 属性**（通过 opaque LSA 或 BGP-LS）：管理组、最大链路带宽、最大
  可预留带宽、未预留带宽、TE 默认度量，以及共享风险链路组（SRLG）
- OSPF **节点角色变化**：路由器成为（或不再是）**ABR**（区域边界路由器）、
  **ASBR**（AS 边界路由器），或进入/退出 **max-metric**（RFC 3137 stub
  router——所有 transit 链路都以最大度量通告，以将 transit 流量引导离开该
  路由器；这是 OSPF 中与 IS-IS overload bit 相对应的机制）

![OSPF 监控——新子网事件](../assets/ospf_monitoring_new_subnet.png)

![OSPF 监控——度量变化，新旧开销](../assets/ospf_monitoring_change_metric.png)

![OSPF 监控——时间线上的链路 up/down 事件](../assets/ospf_monitoring_down_link.png)

## 建立连接

连接本身的建立方式记录在[获取拓扑数据](../ingestion/index.md)中：

- [**GRE 模式**](../ingestion/gre.md) —— FRR 通过 GRE 隧道建立 OSPF 邻接关系。
  **XDP OSPF 过滤器**保证 Watcher 始终保持仅监听状态。
- [**BGP-LS 模式**](../ingestion/bgp-ls.md) —— 路由器通过 BGP-LS 导出 OSPF
  拓扑；GoBGP + 转发器为 Watcher 提供数据。需要镜像
  **`vadims06/ospf-watcher:v3.1.0`** 或更新版本。

!!! note "兼容性"
    OSPF 网络变化从
    [topolograph v2.27](https://github.com/Vadims06/topolograph/releases/tag/v2.27)
    或更高版本开始会显示在 Topolograph 图上。

## 快速实验环境（containerlab） { #quick-lab-containerlab }

`containerlab/frr01` 下提供了一个现成的实验环境，让您无需任何真实硬件即可
观察 OSPF 变化：

```bash
./containerlab/frr01/prepare.sh
sudo clab deploy --topo ./containerlab/frr01/frr01.clab.yml
```

![OSPF Watcher 容器实验环境日志](../assets/ospfwatcher_containerlab.png)

在这个最小化的搭建中，Watcher 会将拓扑变化打印到文本文件中。添加 Topolograph
和/或 ELK 即可对其进行可视化和搜索——参见[部署规模](index.md#deployment-sizes)表格。

!!! tip "没有设备？使用测试模式"
    设置 `TEST_MODE=True` 即可端到端回放演示 LSDB 和示例事件（邻接关系丢失、
    度量变化）。

## 事件日志格式 { #event-log-format }

Watcher 事件是简单的逗号分隔行。一条主机（邻接关系）事件：

```text
2023-01-01T00:00:00Z,demo-watcher,host,10.10.10.4,down,10.10.10.5,01Jan2023_00h00m00s_7_hosts,0,1234,192.168.145.5
```

> `10.10.10.5` 检测到主机 `10.10.10.4`（接口地址为 `192.168.145.5`，位于
> 区域 `0` / AS `1234`）在该时间戳**下线**。

一条度量变化事件：

```text
2023-01-01T00:00:00Z,demo-watcher,network,192.168.13.0/24,changed,old_cost:10,new_cost:12,10.10.10.1,01Jan2023_00h00m00s_7_hosts,0.0.0.0,1234,internal,0
```

> `10.10.10.1` 检测到内部 stub 网络 `192.168.13.0/24` 的度量从 `10` 变为 `12`。

一条节点标志变化事件：

```text
2023-01-01T00:00:00Z,demo-watcher,node,10.1.1.3,changed,attr:abr,old:0,new:1,10.1.1.3,01Jan2023_00h00m00s_7_hosts,0,1234
```

> `10.1.1.3` 将自己通告为 **ABR**（`abr` `0` → `1`）。每个变化的标志会发出一条
> 事件（OSPF 对应 `abr`、`asbr`、`maxmetric`；IS-IS 对应 `overload`、
> `attached`）。进入 max-metric 状态还会为每条链路发出一条 `metric` 事件，
> 因为每条 transit 链路的开销都会跳变到其最大值。

这些记录就是 Logstash/Fluent Bit 转发给
[ELK](elk-kibana.md)、[Zabbix](zabbix.md) 和 [Webhooks](webhooks.md) 的内容。

## 仅监听模式（XDP） { #listen-only-mode-xdp }

在 GRE 模式下，Watcher 运行一个真实的 FRR 实例——因此至关重要的是，它**绝不能**
向您的 OSPF 域注入前缀。**XDP 过滤器**会检查 FRR 试图发送的每一条 OSPF 消息，
并丢弃任何通告了超出 Watcher 自身 GRE 隧道网络范围的内容。

![XDP 过滤器前后的 Wireshark 抓包对比](../assets/xdp_lsa5_drop.png)

例如，如果 `8.8.8.8/32` 被意外地在 Watcher 上重分发，该 LSA 5 会被 XDP 丢弃，
永远不会到达网络。同样的保护机制也适用于 Database Description 消息，以及
LSA 1 中多余的 stub 网络。

常用命令：

```bash
# Watch XDP drop logs
sudo cat /sys/kernel/debug/tracing/trace_pipe

# Confirm the XDP program is attached to the Watcher's interface
ip l show dev it-vhost1025      # look for "prog/xdp id ..."

# Enable / disable the filter
sudo docker run -it --rm -v ./:/home/watcher/watcher/ --cap-add=NET_ADMIN \
  -u root --network host vadims06/ospf-watcher:latest \
  python3 ./client.py --action enable_xdp --watcher_num <num>
```

## 故障排查

**GRE 模式** —— 确认邻接关系：

```text
show ip ospf neighbor
```

您的设备应该显示为一个邻居。如果没有，请运行 Watcher 附带的诊断脚本
（参见代码仓库的故障排查部分）。

**BGP-LS 模式** —— Watcher 只有在 BGP 会话建立之后才会向 Topolograph 提交数据。
检查方法：

```bash
docker logs watcher<num>-bgpls-ospf-bgplswatcher
docker exec -it watcher<num>-bgpls-ospf-bgplswatcher gobgp neighbor
docker exec -it watcher<num>-bgpls-ospf-bgplswatcher gobgp global rib -a ls
```

完整的验证流程请参见
[BGP-LS 会话](../ingestion/bgp-ls.md#3-verify-the-bgp-ls-session)。

---

**相关内容：** [IS-IS Watcher](isis-watcher.md) ·
[ELK / Kibana](elk-kibana.md) · [Zabbix](zabbix.md) · [Webhooks](webhooks.md)

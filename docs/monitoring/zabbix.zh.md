# Zabbix 集成

如果 Zabbix 是您的告警权威系统，Watcher 可以针对拓扑变化——邻居丢失、
transit 链路开销变化、网络被撤销——直接触发**告警**，与您其余的监控内容
放在一起查看。

!!! note "需要 Logstash"
    Zabbix 路径使用默认的（Logstash）profile。在 Fluent Bit profile 下
    **不可用**。

## 哪些内容会触发告警

Watcher 在 `docs/zabbix-ui/` 下附带了现成的 Zabbix 定义。预期有四个
主机/监控项（host 和 item 同名）：

| 监控项 | 触发条件…… |
| --- | --- |
| `ospf_neighbor_up_down` | 建立新的邻接关系，或设备失去其邻居 |
| `ospf_network_up_down` | 某个节点通告或撤销了一个网络 |
| `ospf_link_cost_change` | transit 链路（活动邻居之间）的开销发生变化 |
| `ospf_stub_network_cost_change` | stub 网络的开销发生变化 |

!!! info "为什么 transit 链路开销很重要"
    Transit 链路连接的是活动邻居，因此其开销的变化会改变您的流量所走的
    实际/最短路径——这正是您希望触发告警的那类变化。

**IS-IS Watcher** 提供了等价的 IS-IS 监控项（邻居 up/down、transit 链路
开销变化、网络撤销），共享同一套模板。

## 设置方法

1. 将 Watcher 的 `docs/zabbix-ui/` 目录中的主机/监控项/触发器定义导入
   到您的 Zabbix 服务器。
2. 将 Watcher 的导出目标指向 Zabbix（通过 Logstash 流水线 / `.env` 配置）。
3. 在实验环境中触发一次变化（或等待一次真实的变化发生），确认告警出现在
   您的 Zabbix 仪表盘上。

配置完成后，Watcher 检测到的活动拓扑告警会像其他任何 problem 一样显示在
Zabbix 仪表盘上，latest-data 视图会展示底层的事件数值。

---

**相关内容：** [ELK / Kibana](elk-kibana.md) · [Webhooks & Slack](webhooks.md) ·
[OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)

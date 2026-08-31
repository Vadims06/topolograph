# GRE 会话

在 **GRE 模式**下，Watcher 通过 **GRE 隧道**与您的某台路由器建立真实的
OSPF/IS-IS 邻接关系，然后被动地将每一次链路状态变化转发到 Topolograph。与文本
文件不同，这是一种*实时*数据流——图和事件时间线会随着网络的变化而更新。

GRE 模式几乎适用于任何能够建立 GRE 隧道并在其上运行 OSPF/IS-IS 的路由器，
这使它成为兼容性最广的实时导入方式。

![带有 GRE 邻接关系和 XDP 过滤器的 Watcher 架构](../assets/ospfwatcher_architecture.png)

## 工作原理

- Watcher 在一个隔离的网络命名空间内运行一个 **FRR** 实例。
- 该 FRR 通过 **GRE 隧道**与您的路由器建立 OSPF（或 IS-IS）邻接关系。
- 建立邻接后，路由器会像对待任何其他邻居一样，将其 LSDB 泛洪给 Watcher——
  Watcher 会将每一次变化转换为发往 Topolograph、ELK、Zabbix 或 Slack 的事件。

!!! warning "Watcher 是被动的——并受到保护"
    Watcher 是一个**仅监听**的参与者。**XDP OSPF 过滤器**会检查 FRR 实例试图
    通告的一切内容，并丢弃任何通告了超出 Watcher 自身 GRE 隧道网络范围的
    DB description 或 LSUpdate。这确保了 Watcher 永远无法向您的 OSPF 域中
    注入意外的前缀。参见[仅监听模式](../monitoring/ospf-watcher.md#listen-only-mode-xdp)。

每个 Watcher 都将所有路由和更新保留在其**自身的命名空间**内，因此它永远不会
影响宿主机路由或其他 Watcher。

## 1. 在路由器上配置隧道

从设备到运行 Watcher 的主机之间建立一条 GRE 隧道。以 Cisco 为例：

```text
interface Tunnel0
 ip address <gre-tunnel-ip>
 tunnel mode gre
 tunnel source <router-ip>
 tunnel destination <host-ip>
 ip ospf network type point-to-point
```

然后将 GRE 隧道网络加入到路由器的 OSPF/IS-IS 配置中，以便邻接关系能够跨隧道建立。

## 2. 配置 Watcher

在 Watcher 端，GRE 隧道网络在 FRR 配置中设置（OSPF 对应
`quagga/config/ospfd.conf`）。部署 Watcher 的实验环境命名空间（例如通过
containerlab）会创建：

- 一个供 Watcher 及其 FRR 使用的隔离网络命名空间，
- 一对将 Watcher 连接到 Linux 主机的 tap 接口，
- Watcher 命名空间内的 **GRE 隧道**，
- 针对 GRE 流量的 NAT，
- FRR + Watcher 进程，
- 绑定在 Watcher tap 接口上的 **XDP OSPF 过滤器**。

具体步骤位于 Watcher 各自的代码仓库中：
[OSPF Watcher](https://github.com/Vadims06/ospfwatcher) ·
[IS-IS Watcher](https://github.com/Vadims06/isiswatcher)。

!!! tip "没有现成的路由器？使用测试模式"
    设置 `TEST_MODE=True` 即可用一个静态演示 LSDB 文件驱动 Watcher，并回放
    示例变化（邻接关系丢失、度量变化）——非常适合在没有任何设备的情况下
    端到端体验整个流程。此外还有一个现成的
    [containerlab 实验环境](../monitoring/ospf-watcher.md#quick-lab-containerlab)。

## 3. 验证邻接关系

确认 Watcher 的 FRR 将您的路由器视为一个邻居：

在 Watcher 的 FRR 上打开一个 shell 并运行 `vtysh`：

```text
docker exec -it <watcher-container> vtysh
```

```text
show ip ospf neighbor      # OSPF
show isis neighbor         # IS-IS
```

您的网络设备应该出现在输出中。如果没有，Watcher 附带了一个诊断脚本——参见
[OSPF Watcher](../monitoring/ospf-watcher.md) /
[IS-IS Watcher](../monitoring/isis-watcher.md)页面的故障排查部分。

## GRE 与 BGP-LS 对比

GRE 模式每个接入点都需要一条隧道和一个 IGP 邻接关系。如果您的路由器能够通过
**BGP-LS** 导出拓扑，该模式可以完全避免隧道，并且更容易跨区域/级别扩展。

[:octicons-arrow-right-24: 与 BGP-LS 对比](bgp-ls.md)

---

**下一步：**看看 Watcher 如何处理这些数据 →
[OSPF Watcher](../monitoring/ospf-watcher.md) ·
[IS-IS Watcher](../monitoring/isis-watcher.md)

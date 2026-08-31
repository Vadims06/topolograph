# Webhooks & Slack

若需要即时的、面向人的通知，Watcher 可以将每一个事件 `POST` 到一个
**WebHook**——像 **Slack** 这样的通讯工具可以直接接收它。邻接关系一旦
中断，或开销一旦发生变化，一条消息就会立即出现在您的频道中。

## 四步接入 Slack

1. **创建一个 Slack app。**
2. 为该 app **启用 Incoming Webhooks**。
3. **创建一个 Incoming Webhook**——Slack 会生成一个 URL。
4. 在 Watcher 的 `.env` 中，取消 `EXPORT_TO_WEBHOOK_URL_BOOL` 的注释，并将
   生成的 URL 设置为 `WEBHOOK_URL`。

就是这样——拓扑事件现在会以 Slack 消息的形式送达。

!!! tip "支持 Fluent Bit"
    WebHook/HTTP 输出路径在 Logstash 和更轻量的
    [Fluent Bit](elk-kibana.md) profile 下**都可用**，因此即使在没有 ELK
    的最小化部署中，您也可以获得通知。

## 一条通知包含什么

每一个事件都是 Watcher 记录的同一条结构化记录——时间戳、Watcher 名称、
事件类型（`host` / `network` / `metric`）、受影响的对象、状态
（`up` / `down` / `changed`）、检测节点、Topolograph 图名称、区域/级别，
以及 AS 号。完整的逐字段说明请参见
[OSPF Watcher 事件日志格式](ospf-watcher.md#event-log-format)。

因此，一条 Slack 消息就能告诉您，例如：*节点 `10.10.10.5` 检测到主机
`10.10.10.4` 在区域 0 / AS 1234 中下线*——附带足够的上下文，让您可以直接
跳转到 Topolograph 查看影响。

## 任意 HTTP 端点

由于它只是一个普通的 HTTP `POST`，同样的机制可以发送给任何自定义端点——
内部自动化服务、ChatOps 机器人、事故处理流水线——不仅限于 Slack。

---

**相关内容：** [ELK / Kibana](elk-kibana.md) · [Zabbix](zabbix.md) ·
[实时监控概览](index.md)

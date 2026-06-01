# Webhooks & Slack

For instant, human-facing notifications, the Watchers can `POST` each event to a
**WebHook** — which messengers like **Slack** accept directly. The moment an
adjacency drops or a cost changes, a message lands in your channel.

## Slack in four steps

1. **Create a Slack app.**
2. **Enable Incoming Webhooks** for the app.
3. **Create an Incoming Webhook** — Slack generates a URL.
4. In the Watcher's `.env`, uncomment `EXPORT_TO_WEBHOOK_URL_BOOL` and set the
   generated URL as `WEBHOOK_URL`.

That's it — topology events now arrive as Slack messages.

!!! tip "Works with Fluent Bit"
    The WebHook/HTTP output path is available with **both** Logstash and the
    lighter [Fluent Bit](elk-kibana.md) profile, so you can get notifications even
    in a minimal deployment without ELK.

## What a notification carries

Each event is the same structured record the Watcher logs — timestamp, watcher
name, event type (`host` / `network` / `metric`), the object affected, status
(`up` / `down` / `changed`), the detecting node, the Topolograph graph name, area
/ level, and AS number. See the
[OSPF Watcher event log format](ospf-watcher.md#event-log-format) for a full
field-by-field breakdown.

So a single Slack message tells you, for example, that *node `10.10.10.5`
detected host `10.10.10.4` going down in area 0 / AS 1234* — with enough context
to jump straight into Topolograph and see the impact.

## Any HTTP endpoint

Because it's a plain HTTP `POST`, the same mechanism feeds any custom endpoint —
an internal automation service, a ChatOps bot, an incident pipeline — not just
Slack.

---

**Related:** [ELK / Kibana](elk-kibana.md) · [Zabbix](zabbix.md) ·
[Real-time monitoring overview](index.md)

# Webhooks e Slack

Para notificações instantâneas e voltadas ao ser humano, os Watchers podem
fazer `POST` de cada evento para um **WebHook** — que mensageiros como o
**Slack** aceitam diretamente. No momento em que uma adjacência cai ou um
custo muda, uma mensagem chega no seu canal.

## Slack em quatro passos

1. **Crie um app do Slack.**
2. **Habilite Incoming Webhooks** para o app.
3. **Crie um Incoming Webhook** — o Slack gera uma URL.
4. No `.env` do Watcher, descomente `EXPORT_TO_WEBHOOK_URL_BOOL` e defina a
   URL gerada como `WEBHOOK_URL`.

Pronto — os eventos de topologia agora chegam como mensagens no Slack.

!!! tip "Funciona com o Fluent Bit"
    O caminho de saída WebHook/HTTP está disponível tanto com o Logstash
    quanto com o perfil mais leve [Fluent Bit](elk-kibana.md), então você
    pode ter notificações mesmo em uma implantação mínima sem ELK.

## O que uma notificação carrega

Cada evento é o mesmo registro estruturado que o Watcher registra em log —
timestamp, nome do watcher, tipo de evento (`host` / `network` / `metric`),
o objeto afetado, status (`up` / `down` / `changed`), o nó que detectou, o
nome do grafo no Topolograph, área/nível e número de AS. Veja o
[formato do log de eventos do OSPF Watcher](ospf-watcher.md#event-log-format)
para um detalhamento campo a campo.

Assim, uma única mensagem no Slack informa, por exemplo, que *o nó
`10.10.10.5` detectou o host `10.10.10.4` caindo na área 0 / AS 1234* — com
contexto suficiente para você entrar direto no Topolograph e ver o
impacto.

## Qualquer endpoint HTTP

Como é um simples `POST` HTTP, o mesmo mecanismo alimenta qualquer endpoint
personalizado — um serviço interno de automação, um bot de ChatOps, um
pipeline de incidentes — não apenas o Slack.

---

**Relacionado:** [ELK / Kibana](elk-kibana.md) · [Zabbix](zabbix.md) ·
[Visão geral de monitoramento em tempo real](index.md)

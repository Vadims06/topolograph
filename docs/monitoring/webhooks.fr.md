# Webhooks et Slack

Pour des notifications instantanées et lisibles par un humain, les
Watchers peuvent faire un `POST` de chaque événement vers un **WebHook** —
que des messageries comme **Slack** acceptent directement. Au moment où
une adjacence tombe ou où un coût change, un message arrive dans votre
canal.

## Slack en quatre étapes

1. **Créez une app Slack.**
2. **Activez les Incoming Webhooks** pour l'app.
3. **Créez un Incoming Webhook** — Slack génère une URL.
4. Dans le `.env` du Watcher, décommentez `EXPORT_TO_WEBHOOK_URL_BOOL` et
   définissez l'URL générée comme `WEBHOOK_URL`.

C'est tout — les événements de topologie arrivent désormais sous forme de
messages Slack.

!!! tip "Fonctionne avec Fluent Bit"
    Le chemin de sortie WebHook/HTTP est disponible à la fois avec
    Logstash et le profil plus léger [Fluent Bit](elk-kibana.md), vous
    pouvez donc avoir des notifications même dans un déploiement minimal
    sans ELK.

## Ce que contient une notification

Chaque événement est le même enregistrement structuré que celui journalisé
par le Watcher — horodatage, nom du watcher, type d'événement (`host` /
`network` / `metric`), l'objet concerné, statut (`up` / `down` /
`changed`), le nœud détecteur, le nom du graphe Topolograph, zone/niveau,
et numéro d'AS. Voir le
[format du journal d'événements de l'OSPF Watcher](ospf-watcher.md#event-log-format)
pour le détail champ par champ.

Ainsi, un seul message Slack vous indique, par exemple, que *le nœud
`10.10.10.5` a détecté que l'hôte `10.10.10.4` est tombé dans la zone 0 /
AS 1234* — avec assez de contexte pour aller directement dans Topolograph
et voir l'impact.

## N'importe quel endpoint HTTP

Comme il s'agit d'un simple `POST` HTTP, le même mécanisme alimente
n'importe quel endpoint personnalisé — un service d'automatisation
interne, un bot ChatOps, un pipeline d'incidents — pas seulement Slack.

---

**Voir aussi :** [ELK / Kibana](elk-kibana.md) · [Zabbix](zabbix.md) ·
[Vue d'ensemble de la surveillance en temps réel](index.md)

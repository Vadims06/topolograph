# Intégration Zabbix

Si Zabbix est votre système d'alerte de référence, les Watchers peuvent
déclencher des **alarmes** sur les changements de topologie — un voisin
perdu, le coût d'un lien de transit modifié, un réseau retiré — aux côtés
du reste de votre supervision.

!!! note "Nécessite Logstash"
    Le chemin Zabbix utilise le profil par défaut (Logstash). Il n'est
    **pas** disponible avec le profil Fluent Bit.

## Ce qui déclenche une alarme

Le Watcher fournit des définitions Zabbix prêtes à l'emploi sous
`docs/zabbix-ui/`. Quatre hosts/items (même nom sur le host et l'item)
sont attendus :

| Item | Se déclenche quand… |
| --- | --- |
| `ospf_neighbor_up_down` | Une nouvelle adjacence se forme, ou un équipement perd son voisin |
| `ospf_network_up_down` | Un réseau est annoncé ou retiré d'un nœud |
| `ospf_link_cost_change` | Le coût d'un lien de transit (entre voisins actifs) change |
| `ospf_stub_network_cost_change` | Le coût d'un réseau stub change |

!!! info "Pourquoi le coût des liens de transit compte"
    Les liens de transit relient des voisins actifs, donc un changement de
    coût à cet endroit peut modifier les chemins réels/les plus courts
    suivis par votre trafic — exactement le genre de changement pour
    lequel vous voulez une alarme.

L'**IS-IS Watcher** fournit les items IS-IS équivalents (voisin up/down,
changement de coût sur les liens de transit, retrait de réseau), en
partageant le même jeu de templates.

## Mise en place

1. Importez les définitions de host/item/trigger depuis le répertoire
   `docs/zabbix-ui/` du Watcher dans votre serveur Zabbix.
2. Dirigez l'export du Watcher vers Zabbix (configuré via le pipeline
   Logstash / `.env`).
3. Provoquez un changement dans un labo (ou attendez-en un réel) et
   vérifiez que l'alarme apparaît sur votre tableau de bord Zabbix.

Une fois configurées, les alarmes de topologie actives détectées par le
Watcher apparaissent sur le tableau de bord Zabbix comme n'importe quel
autre problème, la vue des dernières données exposant les valeurs
d'événement sous-jacentes.

---

**Voir aussi :** [ELK / Kibana](elk-kibana.md) · [Webhooks et Slack](webhooks.md) ·
[OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)

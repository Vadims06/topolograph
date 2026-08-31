# IS-IS Watcher

**IS-IS Watcher** est l'équivalent IS-IS de l'[OSPF Watcher](ospf-watcher.md).
Il écoute passivement le plan de contrôle IS-IS — via une
[adjacence GRE](../ingestion/gre.md) ou [BGP-LS](../ingestion/bgp-ls.md) —
et enregistre ou exporte chaque changement vers **ELK**, **Zabbix**, les
**WebHooks**, et le tableau de bord de surveillance de **Topolograph**.
Comme l'OSPF Watcher, il est livré sous forme de conteneurs.

[:simple-github: vadims06/isiswatcher](https://github.com/Vadims06/isiswatcher){ .md-button }

![Architecture IS-IS Watcher + Topolograph](../assets/isiswatcher_architecture.png)

## Événements détectés

- Adjacence de voisin IS-IS **en service/hors service**
- **Changements de coût** de lien IS-IS
- Réseaux IS-IS **apparaissant/disparaissant**
- **Attributs TE** IS-IS : groupe administratif, bande passante maximale du
  lien, bande passante réservable maximale, bande passante non réservée,
  métrique TE par défaut, et groupe de liens à risque partagé (SRLG)
- **Indicateurs de nœud** IS-IS : transitions **overload (OL)** et
  **attached (ATT)** (plus ABR/ASBR dérivés via BGP-LS)

Tout est regroupé par **niveau IS-IS (L1/L2)** sur la chronologie :

![Tableau de bord Topolograph avec événements IS-IS L1/L2](../assets/dashboard_l1_l2_events.png)

!!! example "À quoi ressemblent les niveaux"
    Une capture typique pourrait montrer : un changement de métrique sur un
    lien apparaissant comme **des logs dupliqués pour L1 et L2** ; un
    routeur passant **hors service pour L2 uniquement** après application
    de `isis circuit-type level-1` ; un changement de métrique ultérieur
    visible **uniquement en L1** ; et un nouveau réseau stub apparaissant
    **en L2**.

## Le connecter

La mise en place de la connexion se trouve sous
[Importer la topologie](../ingestion/index.md) :

- [**Mode GRE**](../ingestion/gre.md) — FRR établit une adjacence IS-IS via
  un tunnel GRE ; un **filtre XDP IS-IS** maintient le Watcher en écoute
  seule en rejetant tout LSP qui annonce plus que le réseau du Watcher
  lui-même.
- [**Mode BGP-LS**](../ingestion/bgp-ls.md) — le routeur exporte la
  topologie IS-IS via BGP-LS ; GoBGP + le forwarder alimentent le Watcher.

![Instances FRR GRE individuelles par zone](../assets/gre_frr_instances.png)

!!! warning "Un tunnel GRE par zone"
    IS-IS, comme OSPF, inonde par zone/niveau. En mode GRE, vous avez
    besoin d'**au moins un tunnel GRE dans chaque zone** que vous souhaitez
    surveiller — c'est une propriété de l'inondation à état de liens, pas
    une limitation de l'outil. BGP-LS évite cela en transportant tout le
    domaine sur une seule session.

!!! note "Compatibilité"
    Les changements de réseau IS-IS apparaissent sur le graphe à partir de
    [topolograph v2.38](https://github.com/Vadims06/topolograph/releases/tag/v2.38)
    ou ultérieur.

## Support des TLV et des métriques

IS-IS Watcher analyse les métriques à l'ancien style (narrow) et au nouveau
style (wide) et prend en charge l'accessibilité IPv6. Les TLV qu'il
comprend — et la matrice de support par fournisseur — sont résumés sur la
page [Fournisseurs pris en charge](../reference/supported-vendors.md#is-is-tlv-support).

TLV clés : IS Reachability (2), Extended IS Reachability (22), IPv4
Internal/Extended Reachability (128/135), et IPv6 Reachability (236).

!!! info "Build FRR personnalisé"
    Exécuter IS-IS via GRE nécessite un build FRR capable de le faire ; le
    dépôt IS-IS Watcher fournit le build nécessaire. Voir le
    [dépôt](https://github.com/Vadims06/isiswatcher) pour les détails.

## Laboratoire rapide (containerlab)

Le dépôt fournit une topologie containerlab pour essayer la surveillance
IS-IS de bout en bout — voir le répertoire `containerlab/` et la table des
[tailles de déploiement](index.md#deployment-sizes) pour savoir comment
ajouter Topolograph et ELK.

!!! tip "Pas d'équipement ? Mode test"
    Comme pour l'OSPF Watcher, `TEST_MODE` rejoue des événements IS-IS de
    démonstration depuis un fichier statique afin que vous puissiez
    exercer tout le pipeline sans matériel.

## Format du journal d'événements

IS-IS Watcher émet les mêmes enregistrements d'événements séparés par des
virgules que l'OSPF Watcher (avec le **niveau** IS-IS transporté en plus)
— si bien que les intégrations [ELK](elk-kibana.md), [Zabbix](zabbix.md)
et [Webhook](webhooks.md) fonctionnent à l'identique. Voir le
[format de journal de l'OSPF Watcher](ospf-watcher.md#event-log-format)
pour un détail champ par champ.

---

**Voir aussi :** [OSPF Watcher](ospf-watcher.md) ·
[Ingénierie de trafic](../analysis/traffic-engineering.md) ·
[ELK / Kibana](elk-kibana.md)

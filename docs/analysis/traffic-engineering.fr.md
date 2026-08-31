# Ingénierie de trafic (TE)

Au-delà du coût IGP de base, OSPF et IS-IS peuvent transporter des
attributs d'**ingénierie de trafic** — bande passante, une métrique TE
distincte, et des groupes/affinités administratifs. Topolograph les analyse
et les rend disponibles pour une visualisation et un filtrage plus riches,
aussi bien pour **OSPF** que pour **IS-IS**.

!!! info "Le TE est optionnel"
    Votre graphe se construit très bien à partir des simples LSA 1/2/5
    (OSPF) ou de la LSDB IS-IS standard. Les données TE sont *en plus* —
    activez-les lorsque vous avez besoin d'une analyse tenant compte de la
    capacité.

## Ce que Topolograph analyse { #what-topolograph-parses }

| Attribut | Nom API/SDK | Signification |
| --- | --- | --- |
| Métrique TE par défaut | `temetric` | Métrique de lien spécifique au TE (indépendante du coût IGP) |
| Groupe administratif | `admin_group` | Affinité / couleur / classe de ressource |
| Bande passante maximale du lien | `max_link_bw` | Capacité physique du lien |
| Bande passante réservable maximale | `max_rsrv_link_bw` | Bande passante disponible pour réservation |
| Bande passante non réservée (par priorité) | `unreserved_bw_0` … `unreserved_bw_7` | Bande passante restante à chacune des 8 priorités TE |
| Groupe de liens à risque partagé | `srlg` | Liste des identifiants SRLG auxquels appartient le lien (RFC 4203 / RFC 5307) |

Les **mêmes noms d'attributs** sont utilisés que les données proviennent
d'OSPF ou d'IS-IS.

## Comment alimenter les données TE

=== "OSPF — fichier texte"

    Incluez **`show ip ospf database opaque-area`** dans le même fichier
    d'import que votre LSDB router/network/external. Les LSA de type 10
    (opaque-area) transportent les données TE ; le reste du graphe est
    construit à partir des LSA 1, 2 et 5 comme d'habitude.

    [:octicons-arrow-right-24: Import de fichier texte](../ingestion/text-file.md)

=== "IS-IS — fichier texte"

    Les attributs TE proviennent directement de la LSDB IS-IS lorsque vous
    utilisez les commandes détaillées standard (par exemple FRR
    **`show isis database detail`**). Aucune commande supplémentaire n'est
    requise au-delà de votre capture IS-IS habituelle.

=== "OSPF / IS-IS — BGP-LS"

    **BGP-LS transporte nativement les attributs TE** — groupe
    administratif, bande passante maximale et réservable, bande passante
    non réservée, SRLG, et métrique TE par défaut — sans avoir besoin de
    l'astuce du LSA opaque. Les mises à jour TE arrivent en direct dans la
    vue de surveillance.

    [:octicons-arrow-right-24: Session BGP-LS](../ingestion/bgp-ls.md)

Lorsque les données TE arrivent via BGP-LS, la page de surveillance affiche
les attributs de lien à mesure que les mises à jour arrivent :

![Attributs de lien TE sur la page de surveillance via BGP-LS](../static/te_link_attributes_on_monitoring_page_full_with_bgpls_1.png)

## Filtrer les liens par attributs TE

Une fois qu'un diagramme dispose de données TE, vous pouvez interroger les
liens sur n'importe quel attribut TE à l'aide des opérateurs de plage
`__gt`, `__lt`, `__gte`, `__lte` — pratique pour trouver les liens qui
violent (ou satisfont) une contrainte TE. Avec le
[SDK Python](../automation/python-sdk.md) :

```python
# Links with TE metric >= 100
edges = graph.edges_list(temetric__gte=100)

# Links with unreserved bandwidth at priority 0 below 1 Gbps
edges = graph.edges_list(unreserved_bw_0__lt=1e9)

# Links between two nodes with max link bandwidth above 10 Gbps
edges = graph.edges_list(src_node="1.1.1.1", dst_node="2.2.2.2", max_link_bw__gt=1e10)
```

Le même filtrage est disponible via l'API REST des liens de diagramme.

## Spécificités IS-IS

Le TE IS-IS repose sur les **métriques étendues** (Extended IS/IP
Reachability, TLV 22/135) et prend en charge l'accessibilité **IPv6**
(TLV 236). Le support des TLV concernés par fournisseur est résumé sur la
page [Fournisseurs pris en charge](../reference/supported-vendors.md#is-is-tlv-support).

## Surveiller les changements TE

Lorsqu'un Watcher est connecté, les changements d'attributs TE sont
capturés comme événements aux côtés des changements de coût et
d'adjacence — voir les vues `te_log` dans
[ELK / Kibana](../monitoring/elk-kibana.md) et la page
[IS-IS Watcher](../monitoring/isis-watcher.md).

---

**Voir aussi :** [Importer la topologie](../ingestion/index.md) ·
[Visualisation et analyse](visualizing.md)

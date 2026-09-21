# Fournisseurs pris en charge

Topolograph construit un graphe à partir de la Link-State Database d'un
seul équipement. Utilisez les commandes ci-dessous pour capturer la LSDB,
puis [importez-la](../ingestion/text-file.md).

## OSPF (OSPFv2)

| Fournisseur | LSA 1 (router) | LSA 2 (network) | LSA 5 (external) | Flags de nœud (ABR/ASBR) | Driver SSH du SDK |
| --- | --- | --- | --- | :---: | :---: |
| Cisco | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ | ✅ |
| Cisco NX-OS | `show ip ospf database router detail` | `show ip ospf database network detail` | `show ip ospf database external detail` | ✅ | ✅ |
| Quagga | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ | ✅ |
| Ruckus | `show ip ospf database link-state router` | `show ip ospf database link-state network` | `show ip ospf database external-link-state` | | ✅ |
| Juniper | `show ospf database router extensive \| no-more` | `show ospf database network extensive \| no-more` | `show ospf database external extensive \| no-more` | ✅ | ✅ |
| Bird | `show ospf state all` | `show ospf state all` | `show ospf state all` | | ✅ |
| Nokia | `show router ospf database type router detail` | `show router ospf database type network detail` | `show router ospf database type external detail` | | ✅ |
| MikroTik | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` | ✅[^mt-flags] | ✅ |
| Huawei | `display ospf lsdb router` | `display ospf lsdb network` | `display ospf lsdb ase` | ✅ | ✅ |
| Palo Alto | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | | ✅ |
| Ubiquiti[^ubnt] | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | | ✅ |
| Allied Telesis | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | | ✅ |
| Extreme | `show ospf lsdb detail lstype router` | `show ospf lsdb detail lstype network` | `show ospf lsdb detail lstype as-external` | | ✅ |
| Ericsson | `show ospf database router detail` | `show ospf database network detail` | `show ospf database external detail` | | ✅ |
| Fortinet | `get router info ospf database router lsa` | `get router info ospf database network lsa` | `get router info ospf database external lsa` | | ✅ |
| FRRouting | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ | ✅ |

[^ubnt]: S'applique à la gamme EdgeRouter et aux anciennes passerelles UniFi
    USG. Les passerelles UniFi plus récentes utilisent le projet
    [FRRouting](https://frrouting.org).

[^mt-flags]: RouterOS 7.18 ou plus récent, qui affiche le champ `bits=`
    dans le dump de la LSA.

!!! info "Flags de nœud (ABR/ASBR)"
    Les routeurs annonçant le bit B (Area Border Router) ou E (AS Boundary
    Router) dans leur Router-LSA sont détectés et affichés dans l'infobulle
    du nœud. Le flag est également consultable via l'API des nœuds
    (`?abr=1`, `?asbr=1`). Les mêmes flags sont rapportés en direct par
    l'[OSPF Watcher](../monitoring/ospf-watcher.md).

!!! tip "Données TE optionnelles (FRRouting)"
    Ajoutez `show ip ospf database opaque-area` au même fichier pour
    obtenir les données de bande passante, de métrique TE et d'admin
    group. Le graphe se construit toujours à partir des seules LSA 1/2/5.
    Voir [Ingénierie de trafic](../analysis/traffic-engineering.md).

## OSPFv3

| Fournisseur | Commande | Réseau stub | External (redistribué) |
| --- | --- | :---: | :---: |
| Arista | `show ipv6 ospf database detail` | ✅ | ✅ |
| IP Infusion OcNOS | `show ipv6 ospf database router`, `network`, `external`, `intra-prefix` | ✅ | ✅ |
| Fortinet FortiOS | `get router info6 ospf database router`, `network`, `external`, `intra-prefix` | ✅ | ✅ |
| MikroTik RouterOS | `/routing/ospf/lsa/print detail without-paging where instance=v3` | ✅ | ✅ |

!!! note
    OcNOS et FortiOS exigent les formes par type de LSA : `show ipv6 ospf database` / `get router info6 ospf database` sans type n'affiche qu'une table d'index, et `intra-prefix` est obligatoire car OSPFv3 ne transporte les préfixes que dans ce LSA.

## IS-IS

| Fournisseur | Commande | Réseau stub | External (redistribué) | Flags de nœud (OL/ATT) |
| --- | --- | --- | --- | :---: |
| Cisco | `show isis database detail` | ✅ | Pas encore (nécessite un exemple de LSDB) | ✅ |
| Juniper | `show isis database extensive` | ✅ (nécessite un exemple de LSDB pour confirmer) | Pas encore (nécessite un exemple de LSDB) | ✅ (nécessite un exemple de LSDB pour confirmer) |
| Nokia | `show router isis database detail` | ✅ (nécessite un exemple de LSDB pour confirmer) | Pas encore (nécessite un exemple de LSDB) | ✅ (nécessite un exemple de LSDB pour confirmer) |
| Huawei | `display isis lsdb verbose` | ✅ (nécessite un exemple de LSDB pour confirmer) | Pas encore (nécessite un exemple de LSDB) | ✅ (nécessite un exemple de LSDB pour confirmer) |
| ZTE | `show isis database verbose` | ✅ (nécessite un exemple de LSDB pour confirmer) | Pas encore (nécessite un exemple de LSDB) | ✅ (nécessite un exemple de LSDB pour confirmer) |
| FRRouting | `show isis database detail` | ✅ | Pas encore (nécessite un exemple de LSDB) | ✅ |
| IP Infusion OcNOS | `show isis database verbose` | ✅ | ✅ | ✅ |
| Fortinet FortiOS | `get router info isis database detail` | ✅ | ✅ | ✅ (nécessite un exemple de LSDB pour confirmer) |
| MikroTik RouterOS | `/routing/isis/lsp/print detail without-paging` | ✅ | ✅ | |

!!! info "Flags de nœud (overload / attached)"
    Overload (OL) et attached (ATT) sont lus depuis la colonne `ATT/P/OL`
    de chaque LSP lors de l'import du fichier texte, et sont également
    rapportés en direct par l'[IS-IS Watcher](../monitoring/isis-watcher.md)
    (qui dérive en plus ABR/ASBR via BGP-LS).

!!! info "Un cas non pris en charge ?"
    Plusieurs scénarios IS-IS sont marqués « nécessite un exemple de LSDB » —
    si vous pouvez partager un exemple de base de données, le support peut
    être ajouté. Ouvrez une issue sur le dépôt concerné.

## Support des TLV IS-IS { #is-is-tlv-support }

Le parser IS-IS (utilisé par Topolograph et par
l'[IS-IS Watcher](../monitoring/isis-watcher.md)) comprend les TLV
suivants :

| TLV | # | RFC | Cisco | Juniper | Nokia | FRR | Huawei | ZTE | MikroTik |
| --- | :-: | --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| IS Reachability | 2 | ISO 10589 | ✅ | ✅ | ✅ | ✅ |  | ✅ | ✅ |
| Extended IS Reachability (new) | 22 | RFC 5305 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv4 Internal Reachability (old) | 128 | RFC 1195 | ✅ | ✅ | ✅ | ✅ | ✅ |  | ✅ |
| IPv4 External Reachability (old) | 130 | RFC 1195 |  |  |  |  |  |  |  |
| Extended IPv4 Reachability (new) | 135 | RFC 5305 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv6 Reachability | 236 | RFC 5308 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Les métriques **narrow** (ancien style) et **wide** (nouveau style) sont
toutes deux analysées. Les métriques wide portent des attributs TE — voir
[Ingénierie de trafic](../analysis/traffic-engineering.md).

## Attributs TE par fournisseur { #te-attributes-by-vendor }

Ce que l'analyseur de chaque fournisseur convertit en attributs de lien. Une cellule vide signifie que l'attribut n'est pas lu depuis cette sortie, même si le routeur l'annonce. Une session [Watcher](../monitoring/isis-watcher.md) ou BGP-LS transporte tous les attributs annoncés par le routeur.

### IS-IS { #te-is-is }

| Attribut TE | Nom API/SDK | Défini dans | FRR | Nokia | ZTE | OcNOS |
| --- | --- | --- | :-: | :-: | :-: | :-: |
| Métrique TE par défaut | `temetric` | RFC 5305 §3.7, sub-TLV 18 | ✅ | ✅ |  | ✅ |
| Groupe administratif | `admin_group` | RFC 5305 §3.1, sub-TLV 3 | ✅ | ✅ | ✅ |  |
| Bande passante maximale du lien | `max_link_bw` | RFC 5305 §3.4, sub-TLV 9 | ✅ | ✅ | ✅ |  |
| Bande passante réservable maximale | `max_rsrv_link_bw` | RFC 5305 §3.5, sub-TLV 10 | ✅ | ✅ | ✅ |  |
| Bande passante non réservée (par priorité) | `unreserved_bw_0` … `unreserved_bw_7` | RFC 5305 §3.6, sub-TLV 11 | ✅ | ✅ | ✅ |  |
| Groupe de liens à risque partagé | `srlg` | RFC 5307 §1.2, TLV 138 | ✅ |  |  |  |
| Adresse de l'interface / du voisin | `local_ip_address`, `remote_ip_address` | RFC 5305 §3.2, §3.3, sub-TLVs 6 / 8 | ✅ | ✅ | ✅ |  |
| Identifiant local / distant du lien | `link_local_id`, `link_remote_id` | RFC 5307 §1.1, sub-TLV 4 |  |  | ✅ |  |

Commandes qui affichent les sous-TLV : `show isis database detail` (FRR), `show router isis database detail` (Nokia SR OS), `show isis database verbose` (ZTE, IP Infusion OcNOS). OcNOS n'affiche les sous-TLV TE qu'avec `verbose`, pas avec `detail`.

!!! note
    FRR n'affiche le SRLG que dans les builds qui incluent [FRRouting/frr#22392](https://github.com/FRRouting/frr/pull/22392).

### OSPF { #te-ospf }

| Attribut TE | Nom API/SDK | Défini dans | FRR | OcNOS |
| --- | --- | --- | :-: | :-: |
| Métrique TE par défaut | `temetric` | RFC 3630 §2.5.5, sub-TLV 5 | ✅ | ✅ |
| Groupe administratif | `admin_group` | RFC 3630 §2.5.9, sub-TLV 9 | ✅ |  |
| Bande passante maximale du lien | `max_link_bw` | RFC 3630 §2.5.6, sub-TLV 6 | ✅ |  |
| Bande passante réservable maximale | `max_rsrv_link_bw` | RFC 3630 §2.5.7, sub-TLV 7 | ✅ |  |
| Bande passante non réservée (par priorité) | `unreserved_bw_0` … `unreserved_bw_7` | RFC 3630 §2.5.8, sub-TLV 8 | ✅ |  |
| Groupe de liens à risque partagé | `srlg` | RFC 4203 §1.3, sub-TLV 16 |  |  |
| Adresse de l'interface locale / distante | `local_ip_address`, `remote_ip_address` | RFC 3630 §2.5.3, §2.5.4, sub-TLVs 3 / 4 | ✅ | ✅ |

Ajoutez `show ip ospf database opaque-area` au même fichier de chargement. OcNOS affiche la métrique TE sous le nom `Admin Metric`.

## RFC pris en charge { #supported-rfcs }

RFC implémentés dans les analyseurs et les calculs de Topolograph.

| Protocole | RFC | Ce que lit Topolograph |
| --- | --- | --- |
| OSPFv2 | RFC 2328 | LSA Router (1), Network (2) et AS-External (5) |
| OSPFv2 | RFC 3630 | Attributs TE des liens issus des LSA opaque-area (type 10) |
| OSPFv2 | RFC 4203 | Groupe de liens à risque partagé (SRLG), lorsque les valeurs proviennent d'un Watcher |
| OSPFv2 | RFC 6987 | Drapeau stub router (max-metric) sur les nœuds |
| OSPFv3 | RFC 5340 | LSA Router, Network, AS-External et Intra-Area-Prefix |
| IS-IS | ISO/IEC 10589 | IS Reachability (TLV 2), bases Level 1 / Level 2, bits overload et attached |
| IS-IS | RFC 1195 | IPv4 Internal Reachability (TLV 128) |
| IS-IS | RFC 5305 | Extended IS et IPv4 Reachability (TLV 22, 135) et sous-TLV TE |
| IS-IS | RFC 5307 | Groupe de liens à risque partagé (TLV 138) et identifiants local / distant du lien |
| IS-IS | RFC 5308 | IPv6 Reachability (TLV 236) |
| MPLS TE | RFC 3209 | Priorités setup et holding dans le placement CSPF des tunnels LSP |
| BGP | RFC 4271, RFC 4456, RFC 4364 | Sélection du meilleur chemin, route reflection et routes VPN |
| BGP | RFC 7854, RFC 8671, RFC 9069 | BMP : Adj-RIB-In / Adj-RIB-Out et Loc-RIB |

## Ingestion via BGP-LS

Au-delà des fichiers texte, la topologie OSPF et IS-IS peut être importée
en direct via **BGP-LS**, avec le Watcher correspondant. Voir
[Session BGP-LS](../ingestion/bgp-ls.md).

---

Le schéma d'API canonique et interactif est toujours disponible sur
`/api/ui/` de votre instance.

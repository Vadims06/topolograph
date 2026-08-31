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

## IS-IS

| Fournisseur | Commande | Réseau stub | External (redistribué) | Flags de nœud (OL/ATT) |
| --- | --- | --- | --- | :---: |
| Cisco | `show isis database detail` | ✅ | Pas encore (nécessite une LSDB testée) | ✅ |
| Juniper | `show isis database extensive` | ✅ (nécessite une LSDB testée pour confirmer) | Pas encore (nécessite une LSDB testée) | ✅ (nécessite une LSDB testée pour confirmer) |
| Nokia | `show router isis database detail` | ✅ (nécessite une LSDB testée pour confirmer) | Pas encore (nécessite une LSDB testée) | ✅ (nécessite une LSDB testée pour confirmer) |
| Huawei | `display isis lsdb verbose` | ✅ (nécessite une LSDB testée pour confirmer) | Pas encore (nécessite une LSDB testée) | ✅ (nécessite une LSDB testée pour confirmer) |
| ZTE | `show isis database verbose` | ✅ (nécessite une LSDB testée pour confirmer) | Pas encore (nécessite une LSDB testée) | ✅ (nécessite une LSDB testée pour confirmer) |

!!! info "Flags de nœud (overload / attached)"
    Overload (OL) et attached (ATT) sont lus depuis la colonne `ATT/P/OL`
    de chaque LSP lors de l'import du fichier texte, et sont également
    rapportés en direct par l'[IS-IS Watcher](../monitoring/isis-watcher.md)
    (qui dérive en plus ABR/ASBR via BGP-LS).

!!! info "Un cas non pris en charge ?"
    Plusieurs scénarios IS-IS sont marqués « nécessite une LSDB testée » —
    si vous pouvez partager un exemple de base de données, le support peut
    être ajouté. Ouvrez une issue sur le dépôt concerné.

## Support des TLV IS-IS { #is-is-tlv-support }

Le parser IS-IS (utilisé par Topolograph et par
l'[IS-IS Watcher](../monitoring/isis-watcher.md)) comprend les TLV
suivants :

| TLV | # | Cisco | Juniper | Nokia | FRR | Huawei | ZTE |
| --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| IS Reachability | 2 | ✅ | ✅ | ✅ | ✅ | | ✅ |
| Extended IS Reachability (new) | 22 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv4 Internal Reachability (old) | 128 | ✅ | ✅ | ✅ | ✅ | ✅ | |
| IPv4 External Reachability (old) | 130 | | | | | | |
| Extended IPv4 Reachability (new) | 135 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv6 Reachability | 236 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Les métriques **narrow** (ancien style) et **wide** (nouveau style) sont
toutes deux analysées. Les métriques wide portent des attributs TE — voir
[Ingénierie de trafic](../analysis/traffic-engineering.md).

## Ingestion via BGP-LS

Au-delà des fichiers texte, la topologie OSPF et IS-IS peut être importée
en direct via **BGP-LS**, avec le Watcher correspondant. Voir
[Session BGP-LS](../ingestion/bgp-ls.md).

---

Le schéma d'API canonique et interactif est toujours disponible sur
`/api/ui/` de votre instance.

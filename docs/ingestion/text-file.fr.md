# Import de fichier texte

La façon la plus simple d'importer une topologie dans Topolograph : copiez la
base de données d'état de liens depuis **un seul** routeur et collez-la (ou
importez-la). Aucun agent, aucun tunnel, rien qui touche au réseau en
production.

C'est la méthode d'import **manuelle**.

![Import d'un fichier texte LSDB et construction de chemins courts](../assets/text_file_and_short_paths.gif)

## Pourquoi un seul routeur suffit

OSPF et IS-IS sont des protocoles à état de liens : chaque routeur d'une
zone/niveau détient une copie **identique** de la base de données de la
zone. Topolograph reconstruit toute la topologie à partir de cette copie
unique — vous n'avez donc jamais besoin de la collecter plus d'une fois, sur
un seul équipement.

Pour voir le réseau sur plusieurs zones, collectez la sortie d'un **ABR**
(Area Border Router) : il détient la LSDB de toutes les zones auxquelles il est
connecté.

## 1. Collecter la base de données

Exécutez les commandes de base de données LSA/LSP pour votre plateforme et
enregistrez la sortie dans un fichier texte brut. La matrice complète figure
ci-dessous ; voir [Fournisseurs pris en charge](../reference/supported-vendors.md)
pour les détails OSPFv3 et TLV IS-IS.

=== "OSPF (OSPFv2)"

    | Fournisseur | LSA 1 (router) | LSA 2 (network) | LSA 5 (external) |
    | --- | --- | --- | --- |
    | Cisco | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |
    | Cisco NX-OS | `show ip ospf database router detail` | `show ip ospf database network detail` | `show ip ospf database external detail` |
    | Quagga | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |
    | Ruckus | `show ip ospf database link-state router` | `show ip ospf database link-state network` | `show ip ospf database external-link-state` |
    | Juniper | `show ospf database router extensive \| no-more` | `show ospf database network extensive \| no-more` | `show ospf database external extensive \| no-more` |
    | Bird | `show ospf state all` | `show ospf state all` | `show ospf state all` |
    | Nokia | `show router ospf database type router detail` | `show router ospf database type network detail` | `show router ospf database type external detail` |
    | MikroTik | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` |
    | Huawei | `display ospf lsdb router` | `display ospf lsdb network` | `display ospf lsdb ase` |
    | Palo Alto | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` |
    | Ubiquiti[^ubnt] | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |
    | Allied Telesis | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |
    | Extreme | `show ospf lsdb detail lstype router` | `show ospf lsdb detail lstype network` | `show ospf lsdb detail lstype as-external` |
    | Ericsson | `show ospf database router detail` | `show ospf database network detail` | `show ospf database external detail` |
    | Fortinet | `get router info ospf database router lsa` | `get router info ospf database network lsa` | `get router info ospf database external lsa` |
    | FRRouting | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |

    [^ubnt]: S'applique à la gamme EdgeRouter et aux anciennes passerelles
        UniFi USG. Les passerelles UniFi plus récentes utilisent le projet
        [FRRouting](https://frrouting.org).

=== "OSPFv3"

    | Fournisseur | Commande |
    | --- | --- |
    | Arista | `show ipv6 ospf database detail` |

=== "IS-IS"

    | Fournisseur | Commande de base de données |
    | --- | --- |
    | Cisco | `show isis database detail` |
    | Juniper | `show isis database extensive` |
    | Nokia | `show router isis database detail` |
    | Huawei | `display isis lsdb verbose` |
    | ZTE | `show isis database verbose` |

Vous pouvez placer les sections LSA 1 / 2 / 5 (OSPF) dans un seul fichier —
Topolograph les analyse ensemble.

!!! tip "Optionnel : liens plus riches avec les données TE"
    Pour FRRouting OSPF, ajoutez `show ip ospf database opaque-area` au même
    fichier pour inclure la bande passante du lien, la métrique TE et le
    groupe administratif. Le graphe se construit tout de même sans cela. Voir
    [Ingénierie de trafic](../analysis/traffic-engineering.md).

## 2. L'importer

1. Ouvrez Topolograph (`http://localhost:8080/` pour une
   [installation locale](../getting-started/quickstart-docker.md)).
2. Démarrez un import de topologie et collez ou joignez votre fichier texte.
3. Sélectionnez le **fournisseur** et le **protocole** correspondants
   (OSPF / IS-IS).
4. Validez. Topolograph analyse la base de données et affiche le graphe.

![Import d'un fichier texte LSDB et construction de chemins courts](../assets/text_file_and_short_paths.gif)

Le résultat est un **instantané** — une image figée du réseau au moment de
la capture. Chaque analyse s'exécute sur cet instantané, donc rien de ce que
vous essayez n'affecte la production.

## 3. Comparer les états dans le temps

Importez une autre capture plus tard et Topolograph peut **comparer** les
deux instantanés, en mettant en évidence exactement ce qui a changé —
nœuds et liens ajoutés/supprimés, changements de coût, et réseaux
apparaissant/disparaissant. Voir
[Comparaison des états du réseau](../analysis/comparing-states.md).

## Importer via l'API à la place

Tout ce que vous pouvez coller, vous pouvez aussi le `POST`er. Le
[SDK Python](../automation/python-sdk.md) encapsule cela — et peut même
collecter la LSDB depuis vos équipements via SSH et l'importer en une seule
étape :

```bash
topo ingest inventory.yaml --upload --url http://localhost:8080
```

```python
graph = topo.uploader.upload_raw(
    lsdb_text=raw_text,
    vendor="FRR",
    protocol="isis",
)
```

---

**Vous voulez des mises à jour en direct plutôt que des instantanés ?**
Diffusez la topologie avec une session Watcher [GRE](gre.md) ou
[BGP-LS](bgp-ls.md).

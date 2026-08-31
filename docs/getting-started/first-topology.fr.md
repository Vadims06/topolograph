# Votre première topologie

Ce guide vous emmène d'une instance Topolograph fraîchement démarrée jusqu'à
votre premier graphe analysé, en utilisant l'entrée la plus simple : un
**fichier texte** copié depuis un routeur.

!!! info "Vous aurez besoin de"
    - Une instance Topolograph en fonctionnement ([installation avec Docker](quickstart-docker.md)).
    - L'accès à **un seul** routeur de la zone OSPF ou IS-IS que vous souhaitez cartographier.

## 1. Récupérer la LSDB d'un équipement

Comme toute la zone partage une seule base de données, vous n'avez besoin de
la collecter que sur un seul routeur. Choisissez la commande correspondant à
votre plateforme — la matrice complète se trouve sur la page
[Fournisseurs pris en charge](../reference/supported-vendors.md). Par exemple :

=== "Cisco (OSPF)"

    ```
    show ip ospf database router
    show ip ospf database network
    show ip ospf database external
    ```

=== "Juniper (OSPF)"

    ```
    show ospf database router extensive | no-more
    show ospf database network extensive | no-more
    show ospf database external extensive | no-more
    ```

=== "FRRouting (OSPF)"

    ```
    show ip ospf database router
    show ip ospf database network
    show ip ospf database external
    ```

=== "Cisco (IS-IS)"

    ```
    show isis database detail
    ```

Enregistrez la sortie dans un fichier texte brut. Vous pouvez coller les
sections LSA 1 / 2 / 5 dans un seul fichier.

!!! tip "Liens plus riches (optionnel)"
    Pour FRRouting OSPF, ajoutez la sortie de
    `show ip ospf database opaque-area` au même fichier pour récupérer les
    données de bande passante, de métrique TE et de groupe d'administration.
    C'est optionnel — le graphe se construit tout de même à partir des seuls
    LSA 1/2/5. Voir [Ingénierie de trafic](../analysis/traffic-engineering.md).

## 2. L'importer

1. Ouvrez Topolograph sur `http://localhost:8080/`.
2. Choisissez d'importer une topologie et collez (ou importez) votre fichier
   texte.
3. Sélectionnez le **fournisseur** et le **protocole** correspondant à votre
   capture.
4. Validez — Topolograph analyse la LSDB et affiche le graphe.

![Import d'une LSDB et obtention d'un graphe](../assets/text_file_and_short_paths.gif)

Le résultat est un **instantané** : une image figée de l'état du réseau au
moment où vous avez capturé la base de données. Toutes les analyses que vous
effectuez portent sur cet instantané, si bien que rien de ce que vous faites
ici ne peut affecter le réseau en production.

## 3. Construire un chemin le plus court

Une fois le graphe affiché, choisissez un nœud source et un nœud destination
et construisez le chemin le plus court entre eux. Topolograph met le chemin en
surbrillance et affiche son coût total.

![Construction d'un arbre des chemins les plus courts](../assets/build-spt.gif)

À partir de là, vous pouvez immédiatement :

- Révéler le **chemin de secours** que le réseau utiliserait si le chemin
  principal tombait en panne.
- **Couper un lien ou un nœud** et observer le réacheminement du trafic.
- Ouvrir la **carte de chaleur du réseau** pour repérer vos liens les plus
  chargés et les moins protégés.

Tout cela est couvert dans [Analyse et visualisation](../analysis/index.md).

## 4. Et ensuite ?

<div class="grid cards" markdown>

-   :material-transit-connection-variant:{ .lg .middle } __Le diffuser en direct__

    ---

    Fatigué du copier-coller ? Faites transmettre automatiquement la
    topologie par un Watcher via GRE ou BGP-LS.

    [:octicons-arrow-right-24: Importer la topologie](../ingestion/index.md)

-   :material-vector-polyline:{ .lg .middle } __Approfondir l'analyse__

    ---

    Chemins de secours, ECMP, simulation de pannes, planification des coûts
    et carte de chaleur.

    [:octicons-arrow-right-24: Analyse et visualisation](../analysis/index.md)

-   :material-radar:{ .lg .middle } __Surveiller en continu__

    ---

    Capturez chaque changement d'adjacence et de coût et transmettez-le vers
    ELK, Zabbix ou Slack.

    [:octicons-arrow-right-24: Surveillance en temps réel](../monitoring/index.md)

-   :material-console:{ .lg .middle } __L'automatiser__

    ---

    Collectez et importez des LSDB avec la CLI `topo` et le SDK Python.

    [:octicons-arrow-right-24: SDK Python](../automation/python-sdk.md)

</div>

# Bien démarrer

Nouveau sur Topolograph ? Commencez ici.

<div class="grid cards" markdown>

-   :material-help-circle-outline:{ .lg .middle } __Qu'est-ce que Topolograph ?__

    ---

    Comprenez ce que fait Topolograph, le problème qu'il résout et comment les
    différentes briques de la suite s'articulent entre elles.

    [:octicons-arrow-right-24: Lire la présentation](what-is-topolograph.md)

-   :material-docker:{ .lg .middle } __Démarrage rapide avec Docker__

    ---

    Lancez une instance locale auto-hébergée en quelques minutes avec Docker Compose.

    [:octicons-arrow-right-24: Installer avec Docker](quickstart-docker.md)

-   :material-flag-checkered:{ .lg .middle } __Votre première topologie__

    ---

    Importez une base de données d'état de liens depuis un routeur et construisez
    votre premier chemin le plus court.

    [:octicons-arrow-right-24: Construisez votre premier graphe](first-topology.md)

</div>

## La version en 60 secondes

1. **Exécutez Topolograph** localement avec [Docker](quickstart-docker.md).
2. **Importez votre topologie** — [collez un fichier texte LSDB](../ingestion/text-file.md),
   ou diffusez-la en direct via une session Watcher par [GRE](../ingestion/gre.md) ou
   [BGP-LS](../ingestion/bgp-ls.md).
3. **Analysez-la** — [construisez des chemins, simulez des pannes, repérez les points faibles](../analysis/index.md).
4. **Surveillez-la** — activez un [Watcher](../monitoring/index.md) pour capturer
   chaque changement et être alerté.

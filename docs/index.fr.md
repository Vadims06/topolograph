---
title: Topolograph — visualisation et analyse de topologie OSPF et IS-IS
hide:
  - navigation
  - toc
---

<div class="tg-hero" markdown>
<div class="tg-hero__copy" markdown>

<h1 class="tg-hero__title">Visualisez votre réseau OSPF et IS-IS comme le protocole le voit</h1>

<p class="tg-hero__tagline">
Topolograph construit votre topologie OSPF/IS-IS à partir de la base de données d'état de
liens (LSDB) d'un seul équipement — puis vous permet de tracer les chemins les plus
courts et de secours, de simuler des pannes de liens et de nœuds, de planifier les coûts
de liens et de suivre les changements IGP en temps réel. Auto-hébergé, hors ligne, sans
identifiants ni mots de passe.
</p>

<div class="tg-hero__buttons" markdown>
[Commencer :material-rocket-launch:](getting-started/quickstart-docker.md){ .md-button .tg-cta }
[Qu'est-ce que Topolograph ? :material-help-circle-outline:](getting-started/what-is-topolograph.md){ .md-button }
[Voir sur GitHub :fontawesome-brands-github:](https://github.com/Vadims06/topolograph){ .md-button }
</div>

</div>
<div class="tg-hero__media" markdown>
![Topolograph — importez une LSDB et construisez les chemins les plus courts](assets/text_file_and_short_paths.gif)
</div>
</div>

<div class="tg-vendors" markdown>
<span>Cisco</span> <span>Cisco NX-OS</span> <span>Juniper</span> <span>Nokia</span>
<span>Huawei</span> <span>FRRouting</span> <span>Arista</span> <span>MikroTik</span>
<span>Palo Alto</span> <span>Fortinet</span> <span>Extreme</span> <span>Bird</span>
<span>Ruckus</span> <span>Allied Telesis</span> <span>Ericsson</span> <span>Ubiquiti</span>
</div>

---

## Ce que vous pouvez faire

<div class="grid cards" markdown>

-   :material-graph-outline:{ .lg .middle } __Visualiser la topologie__

    ---

    Importez un fichier texte LSDB ou diffusez-le en direct, et obtenez un graphe
    OSPF/IS-IS interactif qui reflète exactement ce que voient les routeurs.

    [:octicons-arrow-right-24: Importer la topologie](ingestion/index.md)

-   :material-vector-polyline:{ .lg .middle } __Construire des chemins et des secours__

    ---

    Calculez les chemins les plus courts entre deux nœuds quelconques, puis affichez les
    chemins principaux et de secours ainsi que le comportement ECMP.

    [:octicons-arrow-right-24: Analyse et visualisation](analysis/visualizing.md)

-   :material-flash-alert:{ .lg .middle } __Simuler des pannes__

    ---

    Coupez un lien ou un routeur et voyez instantanément comment le trafic se
    réachemine — avant de toucher au réseau de production.

    [:octicons-arrow-right-24: Simulation de pannes](analysis/visualizing.md#simulating-failures)

-   :material-radar:{ .lg .middle } __Surveiller en temps réel__

    ---

    Exécutez OSPF Watcher ou IS-IS Watcher pour capturer chaque changement d'adjacence,
    de coût et de réseau, et envoyez les événements vers ELK, Zabbix ou Slack.

    [:octicons-arrow-right-24: Surveillance en temps réel](monitoring/index.md)

-   :material-fire:{ .lg .middle } __Repérer les points faibles__

    ---

    Utilisez la carte de chaleur du réseau et les analyses pour repérer les liens les
    plus chargés, les points de défaillance uniques et les réseaux sans secours.

    [:octicons-arrow-right-24: Carte de chaleur du réseau](analysis/visualizing.md#network-heatmap)

-   :material-robot-happy-outline:{ .lg .middle } __Automatiser et interroger en langage naturel__

    ---

    Pilotez tout via le SDK et la CLI Python, l'API REST, un serveur MCP ou un agent IA
    en langage naturel.

    [:octicons-arrow-right-24: Automatisation et API](automation/index.md)

</div>

## Trois façons d'importer votre topologie

<div class="grid cards" markdown>

-   __:material-file-document-outline: Fichier texte__

    Collez ou importez la sortie LSDB d'un routeur. Idéal pour les analyses ponctuelles,
    les audits et la planification hors ligne de scénarios hypothétiques.

    [:octicons-arrow-right-24: Import de fichier texte](ingestion/text-file.md)

-   __:material-tunnel: Session GRE__

    Un Watcher établit une adjacence avec un routeur via GRE et transmet les changements
    d'état de liens en direct vers Topolograph.

    [:octicons-arrow-right-24: Session GRE](ingestion/gre.md)

-   __:material-transit-connection-variant: Session BGP-LS__

    Transportez l'état de liens OSPF ou IS-IS nativement via BGP-LS — sans tunnel GRE —
    grâce à GoBGP et au forwarder du Watcher.

    [:octicons-arrow-right-24: Session BGP-LS](ingestion/bgp-ls.md)

</div>

## La suite Topolograph

| Composant | Description | Docs |
| --- | --- | --- |
| **Topolograph** | L'application web : visualiser, analyser, simuler, comparer | [Analyse et visualisation](analysis/index.md) |
| **OSPF Watcher** | Surveillance en direct des changements OSPF (GRE ou BGP-LS) | [OSPF Watcher](monitoring/ospf-watcher.md) |
| **IS-IS Watcher** | Surveillance en direct des changements IS-IS (GRE ou BGP-LS) | [IS-IS Watcher](monitoring/isis-watcher.md) |
| **BMP Watcher** | Sessions BGP, routes et contexte VPN en direct (BMP) | [BMP Watcher](monitoring/bmp-watcher.md) |
| **Python SDK** | Client API orienté objet + collecteur SSH + CLI `topo` | [Python SDK](automation/python-sdk.md) |
| **MCP Server** | Wrapper Model Context Protocol pour agents LLM | [MCP Server](automation/mcp-server.md) |
| **AI Agent** | Assistant en langage naturel pour votre IGP | [AI Agent](automation/ai-agent.md) |

---

<p style="text-align:center; margin-top:2rem;">
Prêt à essayer ? <a href="getting-started/quickstart-docker.md"><strong>Lancez une instance locale avec Docker en quelques minutes →</strong></a>
</p>

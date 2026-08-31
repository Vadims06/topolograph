# Automatisation et API

Tout ce que vous pouvez faire dans l'interface de Topolograph, vous pouvez le
faire par programmation. Choisissez l'interface qui correspond à votre flux de
travail :

<div class="grid cards" markdown>

-   :material-language-python:{ .lg .middle } __SDK Python__

    ---

    Client REST orienté objet, un collecteur LSDB par SSH (Nornir), et la
    CLI `topo`.

    [:octicons-arrow-right-24: SDK Python](python-sdk.md)

-   :material-server-network:{ .lg .middle } __Serveur MCP__

    ---

    Exposez l'API Topolograph aux agents LLM via le Model Context Protocol.

    [:octicons-arrow-right-24: Serveur MCP](mcp-server.md)

-   :material-robot-happy-outline:{ .lg .middle } __Agent IA__

    ---

    Un assistant en langage naturel qui répond aux questions sur votre IGP
    en direct.

    [:octicons-arrow-right-24: Agent IA](ai-agent.md)

</div>

## L'API REST sous-jacente

Tous ces outils reposent sur l'API REST de Topolograph. Le schéma complet et
interactif se trouve sur **`/api/ui/`** de votre instance (pour le service
hébergé, [topolograph.com/api/ui](https://topolograph.com/api/ui/)).

Un import direct est aussi simple que :

```python
import requests

r = requests.post(
    'https://topolograph.com/api/graph',
    auth=('youraccount@domain.com', 'your-pass'),
    json={'ospf_data': '<your LSDB text>'},
)
```

Pour tout ce qui dépasse un appel ponctuel, le [SDK Python](python-sdk.md)
offre une interface bien plus conviviale sur les mêmes endpoints.

!!! tip "Conçu pour les LLM"
    Le modèle de données de Topolograph correspond naturellement aux questions
    en langage naturel, c'est pourquoi le [serveur MCP](mcp-server.md) et
    l'[agent IA](ai-agent.md) existent — demandez « quel est le chemin entre
    ces deux IP ? » plutôt que de construire un appel API.

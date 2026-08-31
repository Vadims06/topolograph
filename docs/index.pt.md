---
title: Topolograph — visualização e análise de topologia OSPF e IS-IS
hide:
  - navigation
  - toc
---

<div class="tg-hero" markdown>
<div class="tg-hero__copy" markdown>

<h1 class="tg-hero__title">Veja sua rede OSPF e IS-IS da mesma forma que o protocolo vê</h1>

<p class="tg-hero__tagline">
O Topolograph constrói a topologia OSPF/IS-IS a partir do banco de dados de estado de
enlace (LSDB) de um único dispositivo — depois permite traçar caminhos mais curtos e de
backup, simular falhas de enlaces e nós, planejar custos de enlace e acompanhar mudanças
no IGP em tempo real. Auto-hospedado, offline, sem logins ou senhas.
</p>

<div class="tg-hero__buttons" markdown>
[Começar :material-rocket-launch:](getting-started/quickstart-docker.md){ .md-button .tg-cta }
[O que é o Topolograph? :material-help-circle-outline:](getting-started/what-is-topolograph.md){ .md-button }
[Ver no GitHub :fontawesome-brands-github:](https://github.com/Vadims06/topolograph){ .md-button }
</div>

</div>
<div class="tg-hero__media" markdown>
![Topolograph — envie uma LSDB e construa caminhos mais curtos](assets/text_file_and_short_paths.gif)
</div>
</div>

<div class="tg-vendors" markdown>
<span>Cisco</span> <span>Cisco NX-OS</span> <span>Juniper</span> <span>Nokia</span>
<span>Huawei</span> <span>FRRouting</span> <span>Arista</span> <span>MikroTik</span>
<span>Palo Alto</span> <span>Fortinet</span> <span>Extreme</span> <span>Bird</span>
<span>Ruckus</span> <span>Allied Telesis</span> <span>Ericsson</span> <span>Ubiquiti</span>
</div>

---

## O que você pode fazer

<div class="grid cards" markdown>

-   :material-graph-outline:{ .lg .middle } __Visualize a topologia__

    ---

    Envie um arquivo de texto LSDB ou transmita-o ao vivo, e obtenha um grafo OSPF/IS-IS
    interativo que reflete exatamente o que os roteadores veem.

    [:octicons-arrow-right-24: Obtendo a topologia](ingestion/index.md)

-   :material-vector-polyline:{ .lg .middle } __Construa caminhos e backups__

    ---

    Calcule os caminhos mais curtos entre quaisquer dois nós e depois revele os caminhos
    primário e de backup, além do comportamento de ECMP.

    [:octicons-arrow-right-24: Análise e visualização](analysis/visualizing.md)

-   :material-flash-alert:{ .lg .middle } __Simule falhas__

    ---

    Desligue um enlace ou um roteador e veja instantaneamente como o tráfego é
    redirecionado — antes de tocar na rede de produção.

    [:octicons-arrow-right-24: Simulação de falhas](analysis/visualizing.md#simulating-failures)

-   :material-radar:{ .lg .middle } __Monitore em tempo real__

    ---

    Execute o OSPF Watcher ou o IS-IS Watcher para capturar cada mudança de adjacência,
    custo e rede, e envie eventos para ELK, Zabbix ou Slack.

    [:octicons-arrow-right-24: Monitoramento em tempo real](monitoring/index.md)

-   :material-fire:{ .lg .middle } __Encontre pontos fracos__

    ---

    Use o Mapa de Calor da Rede e as análises para identificar os enlaces mais
    carregados, pontos únicos de falha e redes sem backup.

    [:octicons-arrow-right-24: Mapa de calor da rede](analysis/visualizing.md#network-heatmap)

-   :material-robot-happy-outline:{ .lg .middle } __Automatize e pergunte em linguagem natural__

    ---

    Controle tudo através do SDK e CLI em Python, da API REST, de um servidor MCP ou de
    um agente de IA em linguagem natural.

    [:octicons-arrow-right-24: Automação e APIs](automation/index.md)

</div>

## Três formas de alimentar sua topologia

<div class="grid cards" markdown>

-   __:material-file-document-outline: Arquivo de texto__

    Cole ou envie a saída da LSDB de um roteador. Ótimo para análises pontuais,
    auditorias e planejamento offline de cenários hipotéticos.

    [:octicons-arrow-right-24: Envio de arquivo de texto](ingestion/text-file.md)

-   __:material-tunnel: Sessão GRE__

    Um Watcher estabelece adjacência com um roteador via GRE e encaminha as mudanças de
    estado de enlace em tempo real para o Topolograph.

    [:octicons-arrow-right-24: Sessão GRE](ingestion/gre.md)

-   __:material-transit-connection-variant: Sessão BGP-LS__

    Transporte o estado de enlace do OSPF ou IS-IS nativamente via BGP-LS — sem túnel
    GRE — usando o GoBGP e o encaminhador do Watcher.

    [:octicons-arrow-right-24: Sessão BGP-LS](ingestion/bgp-ls.md)

</div>

## O conjunto de produtos Topolograph

| Componente | O que é | Documentação |
| --- | --- | --- |
| **Topolograph** | O aplicativo web: visualize, analise, simule, compare | [Análise e visualização](analysis/index.md) |
| **OSPF Watcher** | Monitoramento de mudanças OSPF em tempo real (GRE ou BGP-LS) | [OSPF Watcher](monitoring/ospf-watcher.md) |
| **IS-IS Watcher** | Monitoramento de mudanças IS-IS em tempo real (GRE ou BGP-LS) | [IS-IS Watcher](monitoring/isis-watcher.md) |
| **BMP Watcher** | Sessões BGP, rotas e contexto de VPN em tempo real (BMP) | [BMP Watcher](monitoring/bmp-watcher.md) |
| **Python SDK** | Cliente de API orientado a objetos + coletor SSH + CLI `topo` | [Python SDK](automation/python-sdk.md) |
| **MCP Server** | Wrapper do Model Context Protocol para agentes de LLM | [MCP Server](automation/mcp-server.md) |
| **AI Agent** | Assistente em linguagem natural para o seu IGP | [AI Agent](automation/ai-agent.md) |

---

<p style="text-align:center; margin-top:2rem;">
Pronto para experimentar? <a href="getting-started/quickstart-docker.md"><strong>Suba uma instância local com Docker em poucos minutos →</strong></a>
</p>

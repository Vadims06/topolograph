# Visualizando e analisando

Este é o coração do Topolograph: um grafo interativo OSPF/IS-IS que você
pode examinar com os mesmos algoritmos que os roteadores usam. Tudo abaixo
é executado sobre o seu **snapshot** enviado, então os experimentos nunca
afetam a rede em produção.

## Caminhos mais curtos

Escolha um nó de origem e um de destino e o Topolograph constrói a **árvore
de caminho mais curto** entre eles, destacando o(s) caminho(s) e mostrando o
custo total do IGP.

![Shortest path tree between two nodes](../static/ui/paths.png)

Quando existem múltiplos caminhos de custo igual, o **ECMP** é mostrado
explicitamente para que você veja onde o tráfego é balanceado.

![Topology with ECMP paths](../static/ui/graph-overview.png)

## Caminhos de backup

O Topolograph não mostra apenas o caminho primário — ele calcula o
**caminho de backup** que a rede realmente usaria se o primário falhasse,
incluindo backups **secundários**. Isso responde à pergunta que toda janela
de mudança levanta: *"se este enlace cair, para onde vai o tráfego?"*

![Backup shortest path tree](../static/ui/seven-routers-backup.png)

Ele também distingue os caminhos de backup que passam por ECMP daqueles que
não passam, o que importa quando você raciocina sobre capacidade durante
uma falha.

## Simulando falhas { #simulating-failures }

Teste cenários hipotéticos sem tocar em nada ao vivo.

### Desligar um enlace

Remova um enlace e o Topolograph recalcula os caminhos instantaneamente,
mostrando como o tráfego é redirecionado ao redor dele.

![Network reaction to removing a link](../static/ui/failure.png)

Você pode ver o resultado junto com as estatísticas afetadas:

![Network reaction to a removed edge, with stats](../static/ui/failure-impact-table.png)

### Desligar um nó

Simule a falha de um roteador inteiro e observe o tráfego fluir ao redor do
nó com falha. Clique com o botão direito em um nó e escolha **Fail the router**.

![Network reaction to shutting a node](../static/ui/failure-node-menu.png)

![Result after shutting a node](../static/ui/failure-node-result.png)

## Planejando custos de enlace

Altere uma métrica do IGP em tempo real e veja imediatamente o efeito na
escolha de caminhos — ideal para planejar uma manutenção, deslocar tráfego
para fora de um enlace ou validar um design de custo antes de aplicá-lo.

Verifique se você ainda está no modo **Failure**. Clique com o botão direito em um enlace e escolha **Change the cost…**: um formulário é aberto. Informe o novo custo e clique em **Apply**; o resultado do recálculo das rotas aparece no grafo imediatamente.

![Network reaction to an OSPF cost change](../static/ui/link-cost-change.png)

## Mapa de Calor da Rede { #network-heatmap }

O **Mapa de Calor da Rede** (em **Analysis**) revela propriedades estruturais
da topologia rapidamente — quais enlaces e nós carregam mais caminhos, onde
estão seus pontos únicos de falha e quais redes **não têm caminho de
backup**.

![Network heatmap with networks](../static/ui/network-heatmap.png)

Os nós marcados em vermelho concentram a maior quantidade de redes sem
caminho de backup.

As colunas **Not backed up** do relatório contam, por roteador, as redes sem backup, mostrando exatamente onde uma única falha causaria perda de alcançabilidade.

## Detectando caminhos assimétricos

Um roteamento que segue um caminho na ida e um caminho diferente na volta
pode complicar firewalls, QoS e a solução de problemas. O relatório
**Analysis → Asymmetric paths** do Topolograph encontra esses pares para
você.

![Analysis menu — asymmetric paths](../static/ui/analysis-menu.png)

![A real asymmetric path example](../static/ui/asymmetric-paths.png)

## Para onde ir a seguir

<div class="grid cards" markdown>

-   :material-compare:{ .lg .middle } __Compare dois snapshots__

    ---

    Veja o que mudou entre capturas.

    [:octicons-arrow-right-24: Comparando estados](comparing-states.md)

-   :material-tune-variant:{ .lg .middle } __Adicione dados de TE__

    ---

    Largura de banda, métrica de TE, admin groups.

    [:octicons-arrow-right-24: Traffic Engineering](traffic-engineering.md)

-   :material-radar:{ .lg .middle } __Observe ao vivo__

    ---

    Capture cada mudança à medida que acontece.

    [:octicons-arrow-right-24: Monitoramento em tempo real](../monitoring/index.md)

</div>

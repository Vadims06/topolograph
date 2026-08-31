# Visualizando e analisando

Este é o coração do Topolograph: um grafo interativo OSPF/IS-IS que você
pode examinar com os mesmos algoritmos que os roteadores usam. Tudo abaixo
é executado sobre o seu **snapshot** enviado, então os experimentos nunca
afetam a rede em produção.

## Caminhos mais curtos

Escolha um nó de origem e um de destino e o Topolograph constrói a **árvore
de caminho mais curto** entre eles, destacando o(s) caminho(s) e mostrando o
custo total do IGP.

![Shortest path tree between two nodes](../static/SPT.png)

Quando existem múltiplos caminhos de custo igual, o **ECMP** é mostrado
explicitamente para que você veja onde o tráfego é balanceado.

![Topology with ECMP paths](../static/topology_with_ecmp.png)

## Caminhos de backup

O Topolograph não mostra apenas o caminho primário — ele calcula o
**caminho de backup** que a rede realmente usaria se o primário falhasse,
incluindo backups **secundários**. Isso responde à pergunta que toda janela
de mudança levanta: *"se este enlace cair, para onde vai o tráfego?"*

![Backup shortest path tree](../static/backup_SPT.png)

Ele também distingue os caminhos de backup que passam por ECMP daqueles que
não passam, o que importa quando você raciocina sobre capacidade durante
uma falha.

## Simulando falhas { #simulating-failures }

Teste cenários hipotéticos sem tocar em nada ao vivo.

### Desligar um enlace

Remova um enlace e o Topolograph recalcula os caminhos instantaneamente,
mostrando como o tráfego é redirecionado ao redor dele.

![Network reaction to removing a link](../static/network_reaction_rem_edge1.png)

Você pode ver o resultado junto com as estatísticas afetadas:

![Network reaction to a removed edge, with stats](../static/network_reaction_rem_edge_with_stat.png)

### Desligar um nó

Simule a falha de um roteador inteiro e observe o tráfego fluir ao redor do
nó com falha. Clique com o botão direito em um nó e escolha
**Shutdown this node**.

![Network reaction to shutting a node](../static/network_reaction_shut_node.png)

![Result after shutting a node](../static/network_reaction_result_on_shut_node.png)

## Planejando custos de enlace

Altere uma métrica do IGP em tempo real e veja imediatamente o efeito na
escolha de caminhos — ideal para planejar uma manutenção, deslocar tráfego
para fora de um enlace ou validar um design de custo antes de aplicá-lo.

Verifique se você ainda está na aba **Reação da rede a falhas**. Clique com o
botão direito em um enlace: aparece um formulário com a lista de enlaces.
Defina um novo valor de métrica ao lado do enlace desejado; o resultado do
recálculo das rotas aparece no grafo imediatamente.

![Network reaction to an OSPF cost change](../static/network_reaction_ospf_cost_change.png)

## Mapa de Calor da Rede { #network-heatmap }

O **Mapa de Calor da Rede** (em Analytics) revela propriedades estruturais
da topologia rapidamente — quais enlaces e nós carregam mais caminhos, onde
estão seus pontos únicos de falha e quais redes **não têm caminho de
backup**.

![Network heatmap with networks](../static/network_heatmap_with_networks.png)

Os nós marcados em vermelho concentram a maior quantidade de redes sem
caminho de backup.

Filtre para as redes que **não têm backup** para encontrar exatamente onde
uma única falha causaria perda de alcançabilidade:

![Heatmap highlighting non-backed-up networks](../static/network_heatmap_with_not_backuped_networks.png)

## Detectando caminhos assimétricos

Um roteamento que segue um caminho na ida e um caminho diferente na volta
pode complicar firewalls, QoS e a solução de problemas. O relatório
**Analytics → Asymmetric paths** do Topolograph encontra esses pares para
você.

![Analytics menu — asymmetric paths](../static/analytics_menu_asym_paths.png)

![A real asymmetric path example](../static/asymmetric_path_real_example.png)

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

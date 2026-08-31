# Sua Primeira Topologia

Este passo a passo leva você de um Topolograph recém-instalado até seu
primeiro grafo analisado, usando a entrada mais simples: um **arquivo de
texto** copiado de um roteador.

!!! info "Você vai precisar de"
    - Uma instância do Topolograph em execução ([instale com Docker](quickstart-docker.md)).
    - Acesso a **um** roteador na área OSPF ou IS-IS que você quer mapear.

## 1. Obtenha a LSDB de um dispositivo

Como toda a área compartilha um único banco de dados, você só precisa
coletá-lo de um único roteador. Escolha o comando para a sua plataforma — a
matriz completa está na página [Fornecedores suportados](../reference/supported-vendors.md).
Por exemplo:

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

Salve a saída em um arquivo de texto simples. Você pode colar as seções LSA
1 / 2 / 5 em um único arquivo.

!!! tip "Enlaces mais ricos (opcional)"
    Para o OSPF do FRRouting, anexe a saída de
    `show ip ospf database opaque-area` ao mesmo arquivo para trazer dados de
    largura de banda, métrica de TE e admin-group. Isso é opcional — o grafo
    ainda é construído apenas com as LSAs 1/2/5. Veja
    [Traffic Engineering](../analysis/traffic-engineering.md).

## 2. Envie o arquivo

1. Abra o Topolograph em `http://localhost:8080/`.
2. Escolha enviar uma topologia e cole (ou envie) seu arquivo de texto.
3. Escolha o **fornecedor** e o **protocolo** que correspondem à sua captura.
4. Envie — o Topolograph analisa a LSDB e renderiza o grafo.

![Uploading an LSDB and getting a graph](../assets/text_file_and_short_paths.gif)

O resultado é um **snapshot**: uma imagem congelada do estado da rede no
momento em que você capturou o banco de dados. Toda análise que você executa
acontece sobre esse snapshot, então nada do que você fizer aqui pode afetar a
rede em produção.

## 3. Construa um caminho mais curto

Com o grafo na tela, escolha um nó de origem e um de destino e construa o
caminho mais curto entre eles. O Topolograph destaca o caminho e mostra seu
custo total.

![Building a shortest path tree](../assets/build-spt.gif)

A partir daqui você pode imediatamente:

- Revelar o **caminho de backup** que a rede usaria se o primário falhasse.
- **Desligar um enlace ou nó** e observar o tráfego sendo redirecionado.
- Abrir o **Mapa de Calor da Rede** para encontrar os enlaces mais carregados
  e menos protegidos.

Tudo isso é abordado em [Análise e visualização](../analysis/index.md).

## 4. Para onde ir a seguir

<div class="grid cards" markdown>

-   :material-transit-connection-variant:{ .lg .middle } __Transmita ao vivo__

    ---

    Cansado de copiar e colar? Deixe um Watcher alimentar a topologia
    automaticamente via GRE ou BGP-LS.

    [:octicons-arrow-right-24: Obtendo a topologia](../ingestion/index.md)

-   :material-vector-polyline:{ .lg .middle } __Aprofunde-se na análise__

    ---

    Caminhos de backup, ECMP, simulação de falhas, planejamento de custos e o
    mapa de calor.

    [:octicons-arrow-right-24: Análise e visualização](../analysis/index.md)

-   :material-radar:{ .lg .middle } __Monitore continuamente__

    ---

    Capture cada mudança de adjacência e de custo e envie para ELK, Zabbix ou
    Slack.

    [:octicons-arrow-right-24: Monitoramento em tempo real](../monitoring/index.md)

-   :material-console:{ .lg .middle } __Automatize__

    ---

    Colete e envie LSDBs com a CLI `topo` e o SDK em Python.

    [:octicons-arrow-right-24: SDK em Python](../automation/python-sdk.md)

</div>

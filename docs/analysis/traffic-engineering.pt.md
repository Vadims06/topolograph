# Traffic Engineering (TE)

Além do custo básico do IGP, o OSPF e o IS-IS podem carregar atributos de
**Traffic Engineering** — largura de banda, uma métrica de TE separada e
grupos/afinidades administrativos. O Topolograph analisa esses dados e os
disponibiliza para visualização e filtragem mais ricas, tanto para **OSPF**
quanto para **IS-IS**.

!!! info "TE é opcional"
    Seu grafo é construído normalmente apenas com LSA 1/2/5 (OSPF) ou a LSDB
    padrão do IS-IS. Os dados de TE são *extras* — ative-os quando precisar
    de análise sensível à capacidade.

## O que o Topolograph analisa { #what-topolograph-parses }

| Atributo | Nome na API/SDK | Significado |
| --- | --- | --- |
| Métrica padrão de TE | `temetric` | Métrica de enlace específica de TE (independente do custo do IGP) |
| Grupo administrativo | `admin_group` | Affinity / cor / classe de recurso |
| Largura de banda máxima do enlace | `max_link_bw` | Capacidade física do enlace |
| Largura de banda máxima reservável | `max_rsrv_link_bw` | Largura de banda disponível para reserva |
| Largura de banda não reservada (por prioridade) | `unreserved_bw_0` … `unreserved_bw_7` | Largura de banda restante em cada uma das 8 prioridades de TE |
| Shared risk link group | `srlg` | Lista de ids de SRLG aos quais o enlace pertence (RFC 4203 / RFC 5307) |

Os **mesmos nomes de atributos** são usados independentemente de os dados
virem do OSPF ou do IS-IS.

## Como alimentar dados de TE

=== "OSPF — arquivo de texto"

    Inclua **`show ip ospf database opaque-area`** no mesmo arquivo de envio
    junto com sua LSDB de router/network/external. LSAs do tipo 10
    (opaque-area) carregam os dados de TE; o restante do grafo é construído
    a partir das LSA 1, 2 e 5 como de costume.

    [:octicons-arrow-right-24: Envio de arquivo de texto](../ingestion/text-file.md)

=== "IS-IS — arquivo de texto"

    Os atributos de TE vêm diretamente da LSDB do IS-IS quando você usa os
    comandos detalhados padrão (por exemplo, o FRR **`show isis database detail`**).
    Nenhum comando extra é necessário além da sua captura normal do IS-IS.

=== "OSPF / IS-IS — BGP-LS"

    **O BGP-LS carrega atributos de TE nativamente** — admin group, largura
    de banda máxima e reservável, largura de banda não reservada, SRLG e a
    métrica padrão de TE — sem precisar do truque da LSA opaca. As
    atualizações de TE fluem para a visão de monitoramento ao vivo.

    [:octicons-arrow-right-24: Sessão BGP-LS](../ingestion/bgp-ls.md)

Quando os dados de TE chegam via BGP-LS, a página de monitoramento mostra
os atributos do enlace conforme as atualizações chegam:

![TE link attributes on the monitoring page via BGP-LS](../static/te_link_attributes_on_monitoring_page_full_with_bgpls_1.png)

## Filtrando enlaces por atributos de TE

Uma vez que um diagrama tem dados de TE, você pode consultar enlaces por
qualquer atributo de TE usando os operadores de intervalo `__gt`, `__lt`,
`__gte`, `__lte` — útil para encontrar enlaces que violam (ou satisfazem)
uma restrição de TE. Com o [SDK em Python](../automation/python-sdk.md):

```python
# Links with TE metric >= 100
edges = graph.edges_list(temetric__gte=100)

# Links with unreserved bandwidth at priority 0 below 1 Gbps
edges = graph.edges_list(unreserved_bw_0__lt=1e9)

# Links between two nodes with max link bandwidth above 10 Gbps
edges = graph.edges_list(src_node="1.1.1.1", dst_node="2.2.2.2", max_link_bw__gt=1e10)
```

A mesma filtragem está disponível pela API REST de enlaces do diagrama.

## Especificidades do IS-IS

O TE do IS-IS depende de **wide metrics** (Extended IS/IP Reachability,
TLVs 22/135) e suporta alcançabilidade **IPv6** (TLV 236). O suporte de
cada fornecedor às TLVs relevantes é resumido na página
[Fornecedores suportados](../reference/supported-vendors.md#is-is-tlv-support).

## Monitorando mudanças de TE

Quando um Watcher está conectado, mudanças nos atributos de TE são
capturadas como eventos junto com mudanças de custo e adjacência — veja as
visualizações `te_log` no [ELK / Kibana](../monitoring/elk-kibana.md) e na
página do [IS-IS Watcher](../monitoring/isis-watcher.md).

---

**Relacionado:** [Obtendo a topologia](../ingestion/index.md) ·
[Visualizando e analisando](visualizing.md)

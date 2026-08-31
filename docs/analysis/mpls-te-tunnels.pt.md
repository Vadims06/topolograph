# Túneis MPLS TE

Além das [topologias baseadas em YAML](yaml-topologies.md) e dos
[atributos de Traffic Engineering](traffic-engineering.md), um diagrama
pode declarar **túneis MPLS TE** (no estilo RSVP-TE ou SR-TE) em uma seção
de nível superior `lsps:`. O Topolograph executa o posicionamento CSPF
(Constrained Shortest Path First) sobre eles — as mesmas restrições de
largura de banda/affinity/SRLG de um roteador real, sem nenhuma
sinalização — e visualiza o resultado.

![MPLS TE tunnels: LSP table and placed paths on the graph](../static/mpls-lsp-graph-and-table.png)

A aba **LSP tunnels** lista cada caminho com seu status de posicionamento,
motivo de falha, largura de banda e prioridades; selecionar um nó mostra os
túneis que são ingress, transit ou egress nele, e os caminhos posicionados
são desenhados no canvas.

!!! info "Por enquanto, apenas diagramas YAML"
    `lsps:` está disponível em diagramas baseados em YAML. O suporte a
    túneis reportados ao vivo por um watcher está planejado para um
    lançamento futuro.

## Um túnel em YAML

```yaml
lsps:
  TUN_R1_R3:                    # key = tunnel name
    src: 10.10.10.1
    dst: 10.10.10.3
    metric_type: te             # igp (default) | te
    bandwidth: 2G                # applies to every path unless overridden
    setup_priority: 7
    admin_groups:
      exclude-any: [red]
    color: "#ff9900"
    autoroute: false             # see "autoroute" below
    paths:                       # = LSPs; omit entirely for one dynamic primary
      primary:
        ero:
          - 10.10.10.2                        # plain string = loose hop
          - {node: 10.10.10.3, hop: strict}    # explicit form for a strict hop
      secondary:
        role: standby
        bandwidth: 1G            # overrides the tunnel-level default
        srlg_exclude: [1001]
```

## Referência de chaves

| chave | nível | valores / formato | significado |
|---|---|---|---|
| `lsps` | nível superior | dicionário, nome do túnel → corpo | seção opcional ao lado de `nodes`/`edges` |
| `src`, `dst` | túnel | nome do nó (formato de endereço IP) | extremidades do túnel |
| `metric_type` | túnel | `igp` (padrão) \| `te` | qual métrica o CSPF otimiza |
| `bandwidth` | túnel/caminho | `2G`, `500M`, ou um número bruto em bps | largura de banda exigida; um caminho substitui o padrão do túnel |
| `setup_priority` | túnel/caminho | `0`–`7`, padrão `7` | pool de admissão do RSVP-TE (`0` é o mais forte) |
| `hold_priority` | túnel/caminho | `0`–`7`, padrão igual a `setup_priority` | pool em que a reserva é mantida; não pode ser mais fraco que a prioridade de setup |
| `admin_groups` | túnel/caminho | dicionário: `exclude-any` / `include-any` / `include-all` → lista de nomes | filtro de affinity |
| `srlg_exclude` | caminho | lista de int | restrição de SRLG |
| `color` | túnel | cor CSS | cor de destaque no canvas |
| `autoroute` | túnel | bool, padrão `false` | veja abaixo |
| `paths` | túnel | dicionário, nome do caminho → corpo; omitido = um `primary` dinâmico | os LSPs do túnel |
| `role` | caminho | `primary` (padrão) \| `secondary` \| `standby` | papel do caminho |
| `ero` | caminho | lista: `10.10.10.2` (hop solto) ou `{node: ..., hop: strict}` | rota explícita |

Um caminho herda `bandwidth`, `setup_priority`, `hold_priority` e
`admin_groups` do túnel quando os omite. `srlg_exclude` e `ero` **não** são
herdados — declarar `srlg_exclude` no nível do túnel não tem efeito,
defina-o em cada caminho que precisar dele.

Os enlaces declaram os mesmos atributos de TE cobertos na
[página de Traffic Engineering](traffic-engineering.md#what-topolograph-parses)
(`temetric`, `max_rsrv_link_bw`, `admin_group`/affinity, `srlg`, `unreserved_bw_0`…`unreserved_bw_7`)
— sem nomenclatura separada para fins de MPLS.

### `autoroute`

Um **LSP sinalizado não redireciona tráfego por si só** — isso corresponde
ao comportamento real do RSVP-TE/SR-TE: sem `autoroute announce` (ou uma
rota estática explícita apontando para o túnel), um túnel é apenas largura
de banda reservada, invisível para o cálculo de caminho no estilo IGP.
Defina `autoroute: true` em um túnel para que ele atue como um atalho de
encaminhamento nas consultas de caminho ponta a ponta (veja `with_lsps`
abaixo) — o equivalente no mundo real a ativar o autoroute no headend.

### Prioridade de setup e de holding

`0` é a prioridade mais forte e `7` a mais fraca. Omita `hold_priority` e
ela segue `setup_priority`, o mesmo que o `priority <setup>` de um
roteador com o segundo valor omitido.

Um túnel configurado com prioridade forte mas mantido em uma fraca seria
preemptável no momento em que fosse sinalizado, então essa combinação é
rejeitada: `hold_priority` deve ser pelo menos tão forte quanto
`setup_priority` (`setup_priority: 0` com `hold_priority: 7` é um erro de
validação; `setup_priority: 7` com `hold_priority: 0` é válido).

### Chaves (operacionais) rejeitadas

`rro`, `oper_status`, `active_lsp_name`, e qualquer chave `label_*` são
**rejeitadas** em `lsps:` — elas descrevem estado de sinalização ao vivo
(Record Route, status atual, caminho ativo), não intenção declarada, e só
fazem sentido quando um watcher real as reporta. Um erro de validação é
gerado se você incluir alguma delas.

## Posicionamento CSPF

A cada salvamento, o Topolograph posiciona cada caminho na ordem de
`setup_priority` (convenção do RSVP-TE: `0` é a mais alta), as mesmas
regras que um roteador real aplicaria:

- filtra os enlaces que não têm largura de banda suficiente no pool de
  `setup_priority` solicitado, não satisfazem o filtro de affinity, ou
  estão em um SRLG excluído;
- executa o caminho mais curto sobre o que restou, respeitando qualquer
  `ero` (um hop `strict` deve ser um enlace direto a partir do hop
  anterior — o LSP falha em vez de ser silenciosamente contornado);
- subtrai a largura de banda posicionada daquele pool (e de todo pool de
  prioridade mais baixa) antes de posicionar o próximo caminho.

O posicionamento nunca altera os atributos de TE anunciados
(`unreserved_bw_*`) — a capacidade consumida é rastreada separadamente,
então reexecutar o posicionamento sempre parte dos números realmente
anunciados.

Empates de ECMP são desfeitos de forma determinística: menor número de
hops, depois ordem lexicográfica dos nomes dos nós.

## Lendo os resultados do posicionamento

`GET /api/graph/{graph_time}/lsps` e `GET /api/graph/{graph_time}/lsps/{name}`
retornam o resultado de posicionamento de cada caminho junto com sua
configuração declarada:

```json
{
  "name": "TUN_R1_R3",
  "src": "10.10.10.1",
  "dst": "10.10.10.3",
  "paths": {
    "primary": {
      "placed": true,
      "reason": null,
      "cost": 20,
      "path": ["10.10.10.1", "10.10.10.2", "10.10.10.3"]
    },
    "secondary": {
      "placed": false,
      "reason": "insufficient bandwidth",
      "cost": null,
      "path": []
    }
  }
}
```

`reason` explica *por que* um caminho não posicionado falhou, em palavras.
Junto com ele, `reason_code` fornece a categoria legível por máquina e
`binding_constraints` nomeia o que realmente está bloqueando:

| `reason_code` | significado | o que fazer |
|---|---|---|
| `disconnected` | não existe caminho mesmo removendo todas as restrições | corrija a topologia |
| `constraints_unsatisfiable` | existe um caminho, a solicitação é restritiva demais | relaxe as restrições em `binding_constraints` (`bandwidth`, `affinity`, `srlg`) |
| `ero_strict_hop_unreachable` | um hop strict não tem enlace a partir do hop anterior | corrija o `ero` |
| `endpoint_not_found` | `src`/`dst` não está no grafo | corrija o endpoint |

Várias entradas em `binding_constraints` significam que elas só bloqueiam
em combinação — remover qualquer uma delas já é suficiente.

Filtros úteis no endpoint de listagem:

```python
# Which tunnels failed to place, and why
graph.lsps_list(status="unplaced")

# Which tunnels cross a given node or link (pre-maintenance impact check)
graph.lsps_list(via_node="10.10.10.2")
graph.lsps_list(via_edge="10.10.10.1,10.10.10.2")
```

Quanto de largura de banda de TE ainda resta em um enlace, depois de
contabilizar todos os túneis posicionados:

```python
graph.edges_list(include=["lsp_left_bw"])
# -> ..., "lsp_left_bw_7": ..., "lsp_reserved_bw": "7Gbps",
#    "lsp_left_bw": "3Gbps", "lsp_bandwidth_usage": "7Gbps/3Gbps"
```

## Caminho CSPF, sem declarar um túnel

`cspf_path` responde "qual caminho satisfaz essas restrições, e a que
custo" — um cálculo de caminho mais curto filtrado por restrições, a mesma
classe de consulta que um caminho mais curto simples. Nada é criado ou
persistido:

```python
result = graph.cspf_path(
    "10.10.10.1", "10.10.10.7",
    bandwidth="5G",
    admin_exclude_any=["red"],
)
# {'path': [...], 'cost': 42, 'reason': ''}
# or, if nothing fits: {'path': [], 'cost': None, 'reason': 'no path ... satisfies the requested constraints: ...'}
```

A resposta leva em conta a largura de banda que os **túneis já declarados
mantêm**: em uma topologia com uma seção `lsps:`, a verificação é feita
contra o que resta em cada enlace após o posicionamento, não contra o
valor anunciado, então o resultado nunca promete capacidade que já está
tomada. As restrições são avaliadas por prioridade de setup, então um
enlace pode estar cheio em uma prioridade e ainda ter espaço em uma mais
forte.

As restrições de affinity (`admin_exclude_any`, `admin_include_any`,
`admin_include_all`) comparam **nomes** de affinity no enlace. Topologias
ingeridas de uma rede ao vivo anunciam o admin group como uma bitmask,
então um `include-any`/`include-all` baseado em nome nesses grafos não
casa com nada e a resposta é "sem caminho" — use `exclude-any` ou uma
topologia YAML com affinities nomeadas nesse caso.

## Caminho ponta a ponta via túneis (`with_lsps`)

Por padrão, `graph.paths.shortest(src, dst)` é um caminho IGP simples —
não afetado por nenhum túnel no grafo, assim como o encaminhamento IP real
sem autoroute. Passe `with_lsps=True` para levar em conta túneis com
`autoroute: true` como atalhos de encaminhamento:

```python
graph.paths.shortest("10.10.10.1", "10.10.10.4")               # plain IGP path
graph.paths.shortest("10.10.10.1", "10.10.10.4", with_lsps=True) # via active autoroute tunnels
```

## O que quebra se um enlace cair?

`edge_failure_reaction` prevê o impacto na rede inteira de um ou mais
enlaces falhando — conectividade, e quais enlaces ganham ou perdem
tráfego:

```python
graph.paths.edge_failure_reaction([("10.10.10.1", "10.10.10.2")])
# {'isGraphStillConnected': True, 'affectedLinks': {...}, 'disjointedNodes': []}
```

Para uma visão por túnel da mesma pergunta, combine com
`lsps_list(via_edge=...)` para ver quais túneis atravessam o enlace antes
de verificar o impacto de sua falha.

---

**Relacionado:** [Topologias baseadas em YAML](yaml-topologies.md) ·
[Atributos de Traffic Engineering](traffic-engineering.md) ·
[SDK em Python](../automation/python-sdk.md)

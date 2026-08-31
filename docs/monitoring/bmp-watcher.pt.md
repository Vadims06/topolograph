# BMP Watcher

O **BMP Watcher** traz o plano de controle BGP para o Topolograph: sessões de
peering, as rotas transportadas por elas, o contexto de VPN e cada mudança em
ambos.

Ele é uma estação [BMP](https://datatracker.ietf.org/doc/html/rfc7854) passiva.
Os roteadores abrem uma sessão TCP em direção a ele e enviam a sua Adj-RIB-In.
O watcher não fala BGP, não estabelece peering e nunca se conecta a um roteador
por conta própria — portanto não acrescenta nenhum estado BGP à rede observada.

!!! info "O estado BGP é mantido separado do seu grafo IGP"
    Uma sessão BGP é uma relação de plano de controle, não um enlace de
    encaminhamento. O BGP é armazenado como um grafo próprio, com o seu próprio
    ciclo de vida, e é *vinculado* aos seus grafos OSPF e IS-IS, nunca mesclado
    a eles. Um grafo BGP também funciona sozinho, sem nenhum grafo IGP presente.

---

## O que é coletado

### Famílias de endereços

| Família | AFI | SAFI | Reportada como |
|---|---:|---:|---|
| IPv4 unicast | 1 | 1 | `prefix` |
| IPv6 unicast | 2 | 1 | `prefix` |
| VPNv4 | 1 | 128 | `l3vpn` |
| VPNv6 | 2 | 128 | `l3vpn` |
| EVPN | 25 | 70 | `evpn` |

Uma rota VPN só é única junto com o seu Route Distinguisher, então o RD faz
parte da sua identidade. Uma rota EVPN não tem prefixo algum e é identificada
pelos componentes de NLRI da RFC 7432 — tipo de rota, Ethernet Segment ID,
Ethernet Tag, MAC, IP.

### Mensagens BMP

| Mensagem BMP | O que o Topolograph faz com ela |
|---|---|
| Route Monitoring | monta a tabela e cada mudança de rota subsequente |
| Peer Up | estado da sessão e o BGP Identifier do peer — o Router ID a que os eventos são atribuídos |
| Peer Down | encerramento da sessão e um withdraw por rota que aquele peer carregava |
| Initiation / Termination | ciclo de vida da sessão do coletor |
| Statistics Report | ignorada — contadores não são estado de roteamento |

### Fluxos de política e nível de evidência

Os dois fluxos de Adj-RIB-In são armazenados separadamente e, onde o speaker
suporta a [RFC 9069](https://datatracker.ietf.org/doc/html/rfc9069), o fluxo
Loc-RIB é mantido como uma terceira observação:

| Fluxo | Evidência | Significa |
|---|---|---|
| `pre` / `out-pre` | `pre_policy` | o peer anunciou; o roteador pode tê-la rejeitado |
| `post` / `out-post` | `post_policy` | o roteador aceitou — um caminho candidato |
| `loc-rib` | `loc_rib` | a escolha do próprio roteador — o melhor caminho instalado |
| `fib` | `fib` | presente na tabela de encaminhamento |

Eles nunca são mesclados. Uma rota vista apenas em pre-policy **nunca** é
reportada como selecionada ou instalada — essa distinção é a razão de existirem
os dois fluxos.

### Observações, não sub-redes

O mesmo prefixo é armazenado uma vez por speaker, uma por peer, uma por path ID
e uma por fluxo de política. Todas as cópias sobrevivem, porque "quem anunciou o
quê para quem" é exatamente a pergunta que uma tabela monitorada responde.

---

## Instalando o coletor

O coletor é o [**bmpwatcher**](https://github.com/Vadims06/bmpwatcher) — uma
estação BMP em Go que separa o replay inicial da tabela das mudanças que vêm
depois. O README dele cobre a compilação, a execução em Docker e a configuração
BMP do lado do roteador para FRR, IOS-XR, Junos e SR OS.

Execução mínima, produzindo tanto o snapshot quanto o fluxo de eventos:

```bash
bmpwatcher \
  --bmp-port=11019 \
  --source-id=pe1 \
  --watcher-name=bmp-dc1 \
  --events=/var/log/bmpwatcher/events.jsonl \
  --topolograph-topology-url=https://topolograph.com/api/watcher/bgp
```

!!! warning "A autenticação ainda não está integrada ao coletor"
    `/api/watcher/bgp` exige `Authorization: Bearer sk-...`, e o coletor ainda
    não anexa esse cabeçalho — um envio direto recebe `401`. Até que isso seja
    lançado, escreva o documento localmente com `--topolograph-topology-file` e
    faça o POST você mesmo (veja o exemplo com `curl` abaixo).

Obtenha o token em **Settings → API Tokens → Create token**. O workspace é
resolvido a partir do token no servidor e nunca é lido do payload.

---

## API de ingestão

### `POST /api/watcher/bgp` — o snapshot da topologia

O coletor monta a tabela inteira durante a sua janela de coleta e a envia como
um único documento.

```bash
curl -sS -X POST https://topolograph.com/api/watcher/bgp \
  -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data @topolograph-topology.json
```

```json
{
  "time": "2026-08-17T09:12:03Z",
  "user": "bmp-dc1",
  "srcid": "pe1",
  "sesid": "b4f1c8e2",
  "topology": {
    "nodes": [
      {"name": "10.0.0.1", "asn": "65001", "role": "speaker", "router_ip": "10.0.0.1"},
      {"name": "10.0.0.2", "asn": "65002", "role": "peer"}
    ],
    "edges": [
      {"source": "10.0.0.1", "target": "10.0.0.2",
       "peer_ip": "10.0.0.2", "local_ip": "10.0.0.1", "asn": "65002",
       "peer_type": 0, "policies": ["pre", "post"], "families": ["1/1", "1/128"]}
    ],
    "networks": [
      {"subnet": "192.0.2.0/24", "type": "1", "subtype": 1,
       "bmp_source": "10.0.0.1", "peer_ip": "10.0.0.2",
       "policy": ["post"], "path_id": 0, "nexthop": "10.0.0.2",
       "vpn_rd": "65001:100", "rt": "65001:100",
       "labels": [24001], "data": {}}
    ]
  }
}
```

| Campo | Significado |
|---|---|
| `time` | timestamp do snapshot, ISO 8601 — também a chave de obsolescência |
| `srcid` | a instância do coletor |
| `sesid` | uma *execução* do coletor; muda a cada reinício |
| `nodes[].role` | `speaker` reporta; `peer` apenas foi reportado |
| `edges[]` | uma **sessão** BGP, não um par de roteadores |
| `networks[]` | uma **observação** de rota |
| `networks[].type` / `subtype` | AFI como string, SAFI como número |
| `networks[].data` | o registro original do coletor, para que nenhum atributo não promovido se perca |

**Resposta**

```json
{"graph_time": "17Aug2026_09h12m03s_6_hosts", "checkpoint": false, "routes": 1428}
```

`graph_time` é o identificador público usado por todos os endpoints de leitura
abaixo — o mesmo formato dos grafos IGP.

**Ordenação e reenvios.** O `sesid` é criado quando o coletor inicia, exatamente
quando os speakers reenviam as suas tabelas. Dentro de um mesmo `sesid` vence o
`time` mais recente; um mais antigo ou igual é rejeitado com
`400 stale snapshot`. Um reenvio completo periódico sob o mesmo `sesid` é
tratado como um **checkpoint de reconciliação**, não como um grafo novo — ele
retorna `checkpoint: true`, comprova que a fonte está viva numa rede silenciosa
e corrige a visão atual se ela tiver divergido. Um novo `sesid` substitui a
execução anterior.

Todos os Route Targets são extraídos de `data.base_attrs.ext_community_list`, e
não apenas do campo `rt` promovido — uma rota com vários RTs continua visível
numa busca por qualquer um deles.

### `POST /api/watcher/bgp/events` — o fluxo de mudanças

Aceita um objeto de evento ou uma lista deles.

```bash
curl -sS -X POST https://topolograph.com/api/watcher/bgp/events \
  -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '[{
        "srcid": "pe1", "sesid": "b4f1c8e2", "seq": 41,
        "watcher_time": "2026-08-17T09:14:11Z",
        "event_name": "prefix", "event_status": "withdraw",
        "event_object": "192.0.2.0/24", "event_detected_by": "10.0.0.2",
        "bmp_source": "10.0.0.1", "policy": "post",
        "afi": 1, "safi": 1, "prefix": "192.0.2.0", "prefix_len": 24,
        "family_data": {"peer_ip": "10.0.0.2"}
      }]'
```

| Campo | Significado |
|---|---|
| `event_name` | `prefix`, `l3vpn`, `evpn`, `peer` |
| `event_status` | `add`, `change`, `withdraw` (rotas); `up`, `down` (peers) |
| `event_detected_by` | o roteador a que a mudança se refere |
| `bmp_source` | o speaker que reportou — um roteador diferente em qualquer sessão refletida |
| `seq` | monotônico por `sesid`; usado para deduplicação exata e detecção de lacunas |
| `watcher_time` | relógio do coletor — ordena o fluxo |
| `bmp_timestamp` | relógio do roteador — apenas correlação, nunca ordenação |
| `replay_suspect` | pode ser a cauda de um replay em vez de uma mudança ao vivo |

```json
{"accepted": 1, "duplicates": 0}
```

Um evento cujo `(srcid, sesid)` não corresponde a um snapshot armazenado é
rejeitado — **envie a topologia antes de iniciar o feed de eventos**. Um `seq`
repetido é contado como duplicata e descartado; uma lacuna no `seq` é registrada
como mensagem perdida.

Um evento de peer up/down é apenas informativo. O coletor já emite um withdraw
comum por prefixo para cada rota que o peer caído carregava, portanto o evento
de peer em si nunca altera o estado das rotas.

### `POST /api/watcher/vrfs` — inventário de VRFs

Route Distinguishers identificam rotas VPN, mas apenas o dispositivo conhece o
*nome* da VRF e os seus Route Targets de import/export. Enviar o inventário
permite buscar pelo nome da VRF em vez do RD.

```bash
curl -sS -X POST https://topolograph.com/api/watcher/vrfs \
  -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
        "router_id": "10.0.0.1",
        "observed_at": "2026-08-17T09:10:00Z",
        "vrfs": [{
          "name": "Red",
          "families": [{
            "afi": "ipv4", "safi": "unicast",
            "route_distinguisher": "65001:100",
            "import_route_targets": ["65001:100", "65001:999"],
            "export_route_targets": ["65001:100"]
          }]
        }]
      }'
```

Cada observação é armazenada com o seu próprio timestamp em vez de sobrescrever
a anterior, de modo que um grafo mais antigo ainda consegue resolver o estado da
VRF como ele era naquele momento. A unicidade é `(workspace, router_id, rd)`; um
reenvio sem mudanças não escreve nada.

---

## Vinculação aos seus grafos IGP

Após cada gravação BGP **e** cada gravação IGP, o Topolograph reavalia a quais
grafos OSPF ou IS-IS um grafo BGP pertence. Os candidatos são ordenados pela
sobreposição de Router IDs usando cobertura de conjuntos gulosa, então um grafo
BGP que abrange dois domínios IGP se vincula aos dois.

| Estado | Significado |
|---|---|
| `bound` | sobreposição de Router IDs ≥ 80 %, sem ambiguidade |
| `needs_mapping` | abaixo do limiar, ou dois candidatos empatados — aguardando confirmação |

A sobreposição de Router IDs é **evidência, não requisito**. Um BGP Router ID e
um OSPF Router ID normalmente coincidem, mas o Topolograph nunca exige isso:
resultados ambíguos ficam visíveis para você confirmar.

```bash
# a que um grafo BGP está vinculado
curl -sS ".../api/bgp-graph/17Aug2026_09h12m03s_6_hosts/bindings" -H "Authorization: Bearer $T"

# confirmar um vínculo manualmente
curl -sS -X PUT ".../api/bgp-graph/<bgp_graph_time>/<igp_graph_time>/binding" -H "Authorization: Bearer $T"

# remover um vínculo
curl -sS -X DELETE ".../api/bgp-graph/<bgp_graph_time>/<igp_graph_time>/binding" -H "Authorization: Bearer $T"
```

!!! note "IS-IS precisa de um Router ID real"
    Internamente, um nó IS-IS é nomeado por um pseudo Router ID criado pelo
    parser, que não existe em lugar algum da rede. Apenas um **TE Router ID**
    anunciado pelo dispositivo conta como identidade. Um dispositivo que não
    anuncia nenhum não contribui para a pontuação de sobreposição — o que é o
    resultado honesto, não um defeito. Habilite TE no dispositivo ou defina o
    Router ID à mão na página de **mapeamento de hostnames**; a partir daí ele
    migra para os grafos seguintes como um hostname.

---

## Lendo os dados

### Grafos, nós e sessões

```bash
GET /api/bgp-graphs?page=1&per_page=50
GET /api/bgp-graph/{bgp_graph_time}
GET /api/bgp-graph/{bgp_graph_time}/nodes?role=rr&asn=65001
GET /api/bgp-graph/{bgp_graph_time}/sessions?igp_relation=inter-domain&bgp_session_type=ebgp
```

Cada sessão é classificada assim que os vínculos são conhecidos:

| `igp_relation` | Significado |
|---|---|
| `intra-domain` | ambas as pontas estão no mesmo grafo IGP vinculado |
| `inter-domain` | as pontas estão em dois grafos IGP vinculados diferentes |
| `external` | pelo menos uma ponta não está em nenhum grafo vinculado |

`bgp_session_type` é `ibgp` ou `ebgp`, derivado do ASN da sessão comparado ao do
próprio speaker — e não de `AS_PATH[0]`, que uma rota refletida tornaria
enganoso.

### Busca de rotas

```bash
GET /api/bgp-graph/{bgp_graph_time}/routes?prefix=192.0.2.0/24
GET /api/bgp-graph/{bgp_graph_time}/node/{router_id}/routes?evidence=loc_rib
```

| Parâmetro | Comportamento |
|---|---|
| `prefix=192.0.2.0/24` | correspondência exata do prefixo completo |
| `prefix=192.0.2.5` | contenção — todas as rotas que cobrem o endereço |
| `prefix=192.0.2.0/24&lpm=1` | correspondência do prefixo mais longo, uma linha |
| `afi` / `safi` | família numérica |
| `rd` | Route Distinguisher |
| `vrf` | nome da VRF, resolvido para os seus RDs via inventário |
| `rt` | qualquer Route Target da rota |
| `policy` / `evidence` | fluxo bruto, ou `pre_policy` / `post_policy` / `loc_rib` / `fib` |
| `as_path_contains` | substring em qualquer posição do AS_PATH |
| `community` / `large_community` / `extended_community` | busca por community |
| `origin`, `local_pref`, `med`, `originator_id`, `label` | filtros de atributos |
| `peer_ip`, `nexthop`, `bmp_source` | quem anunciou e como é alcançada |
| `page`, `per_page` | paginação (`per_page` limitado a 500) |

Cada rota carrega VRF/RD/RT, AFI/SAFI, política e evidência, path ID,
communities, next hop, labels e origin.

### Histórico e comparação

```bash
# estado da tabela agora, ou como era em um instante
GET /api/bgp-graph/{bgp_graph_time}/routes/state
GET /api/bgp-graph/{bgp_graph_time}/routes/state?at=2026-08-17T09:20:00Z

# o que mudou entre dois instantes
GET /api/bgp-graph/{bgp_graph_time}/routes/compare?t0=...&t1=...

# o feed de eventos e as faixas da linha do tempo de monitoramento
GET /api/bgp-graph/{bgp_graph_time}/events?last_minutes=60&event_name=peer
GET /api/bgp-graph/{bgp_graph_time}/events/timeline
```

`state` sem `at` lê uma visão atual mantida continuamente, portanto custa o
tamanho da resposta em vez de um replay de todo o log de eventos. Um `at`
explícito reproduz os deltas desde a linha de base do snapshot até aquele
instante. Os limites de tempo são inclusivos nas duas pontas.

`compare` retorna uma linha por mudança: `added`, `withdrawn` ou `changed` com
antes/depois.

Na linha do tempo de monitoramento, `bgp_peer` recebe um marcador por subida ou
queda de sessão — volume baixo, e cada flap importa — enquanto `bgp_route` é
agrupado, de modo que uma rajada de churn de rotas aparece como um único
marcador com contagem, e não como milhares de pontos.

### Route lookup

O route lookup responde "o que este roteador realmente faz com este destino",
em contraste com um SPF puramente topológico.

```bash
GET /api/graph/{graph_time}/route-lookup/{start_node}?destination=192.0.2.5&vrf=Red&with_lsps=1
```

```json
{
  "prefix": "192.0.2.0/24",
  "start_node": "10.0.0.1",
  "route_source": "BGP",
  "admin_distance": 200,
  "nexthop": "10.0.0.9",
  "resolution_chain": ["192.0.2.0/24", "10.0.0.9/32"],
  "path_segments": [{"domain": "17Aug2026_09h05m00s_6_hosts",
                     "path": ["10.0.0.1", "10.0.0.4", "10.0.0.9"]}],
  "warning": null
}
```

A ordem de decisão é deliberada:

1. **Correspondência do prefixo mais longo** dentro da tabela ou VRF escolhida.
2. **Seleção de melhor caminho BGP** — um caminho por prefixo, por LOCAL_PREF,
   comprimento de AS_PATH, ORIGIN e MED, antes que qualquer coisa compare
   protocolos. Uma observação de Loc-RIB encerra a comparação: é a escolha do
   próprio roteador.
3. **Distância administrativa** entre os candidatos sobreviventes de protocolos
   diferentes.
4. **Resolução recursiva de next hop**, com proteção contra laços e
   profundidade.
5. **Transporte IGP SPF/CSPF** até esse next hop, opcionalmente por atalhos LSP
   elegíveis.

| Protocolo | AD |
|---|---:|
| connected | 0 |
| static | 1 |
| eBGP | 20 |
| OSPF | 110 |
| IS-IS | 115 |
| iBGP | 200 |

A distância administrativa pertence às **rotas**, nunca às arestas da topologia.
Métricas de OSPF, IS-IS e BGP nunca são comparadas entre si — uma métrica só faz
sentido dentro do seu próprio protocolo. iBGP versus eBGP é decidido pela sessão
em que a rota foi aprendida, não por `AS_PATH[0]`.

As rotas candidatas são limitadas ao que o nó inicial realmente enxerga: a sua
própria tabela reportada mais as tabelas dos seus vizinhos diretos de sessão. Um
roteador que não roda BGP não herda nada.

---

## Retenção

O Topolograph mantém os grafos BGP mais recentes **por fonte** (`srcid`), então
uma instalação com dois coletores mantém uma janela completa para cada um.
Quando uma época sai da janela, as suas rotas e vínculos vão junto. Reenvios
periódicos sob o mesmo `sesid` são checkpoints e não consomem a janela.

---

## Limites atuais

- O coletor ainda não anexa o token de API; envie o snapshot com `curl` por
  enquanto.
- Rode um coletor por speaker BMP e defina `--source-id`. Vários speakers em um
  coletor misturam as suas observações.
- Rotas EVPN são coletadas e armazenadas, mas a tabela de rotas e o route lookup
  são orientados a prefixos; EVPN ainda não é um objeto de busca de primeira
  classe.
- Um Router ID que legitimamente aparece em dois domínios IGP vinculados é
  resolvido para um deles na classificação de sessões.

---

## Veja também

- [bmpwatcher no GitHub](https://github.com/Vadims06/bmpwatcher)
- [OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)
- [Eventos, Linha do Tempo e Status](events-timeline.md)
- [Sessão BGP-LS](../ingestion/bgp-ls.md) — BGP-LS transporta topologia *IGP*,
  um assunto diferente do estado de roteamento BGP desta página

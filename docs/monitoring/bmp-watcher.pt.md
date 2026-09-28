# BMP Watcher

O **BMP Watcher** traz o plano de controle BGP para o Topolograph: sessões de
peering, as rotas transportadas por elas, o contexto de VPN e cada mudança em
ambos.

Ele é uma estação [BMP](https://datatracker.ietf.org/doc/html/rfc7854) passiva.
Os roteadores abrem uma sessão TCP em direção a ele e enviam a sua Adj-RIB-In.
O watcher não fala BGP, não estabelece peering e nunca se conecta a um roteador
por conta própria - portanto não acrescenta nenhum estado BGP à rede observada.

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
pelos componentes de NLRI da RFC 7432 - tipo de rota, Ethernet Segment ID,
Ethernet Tag, MAC, IP.

### Mensagens BMP

| Mensagem BMP | O que o Topolograph faz com ela |
|---|---|
| Route Monitoring | monta a tabela e cada mudança de rota subsequente |
| Peer Up | estado da sessão e o BGP Identifier do peer - o Router ID a que os eventos são atribuídos |
| Peer Down | encerramento da sessão e um withdraw por rota que aquele peer carregava |
| Initiation / Termination | ciclo de vida da sessão do coletor |
| Statistics Report | ignorada - contadores não são estado de roteamento |

### Fluxos de política e nível de evidência

Os dois fluxos de Adj-RIB-In são armazenados separadamente e, onde o speaker
suporta a [RFC 9069](https://datatracker.ietf.org/doc/html/rfc9069), o fluxo
Loc-RIB é mantido como uma terceira observação:

| Fluxo | Evidência | Significa |
|---|---|---|
| `pre` / `out-pre` | `pre_policy` | o peer anunciou; o roteador pode tê-la rejeitado |
| `post` / `out-post` | `post_policy` | o roteador aceitou - um caminho candidato |
| `loc-rib` | `loc_rib` | a escolha do próprio roteador - o melhor caminho instalado |
| `fib` | `fib` | presente na tabela de encaminhamento |

Eles nunca são mesclados. Uma rota vista apenas em pre-policy **nunca** é
reportada como selecionada ou instalada - essa distinção é a razão de existirem
os dois fluxos.

---

## Instalando o coletor

Para testar sem uma rede real, execute o laboratório containerlab [13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp) do repositório bmpwatcher.

O coletor é o [**bmpwatcher**](https://github.com/Vadims06/bmpwatcher), publicado
como a imagem Docker `vadims06/bmpwatcher:latest`: uma estação BMP passiva à qual os roteadores
se conectam em TCP 11019; ele nunca se conecta a um roteador. Ele separa a carga inicial
da tabela das mudanças que vêm depois. O README dele cobre a configuração BMP do lado do
roteador para FRR, IOS-XR, Junos e SR OS.

Você precisa de uma conta no Topolograph: cadastre-se em topolograph.com ou, em uma
instância self-hosted, entre com o usuário definido no `.env` dela (`TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `TOPOLOGRAPH_WEB_API_PASSWORD`).
Crie um token de API: **API → Token → Create Token**. O workspace é resolvido a partir
do token no servidor e nunca vem do payload.

### Executar com Docker Compose

O arquivo compose do repositório bmpwatcher executa juntos o coletor e o remetente de eventos Fluent Bit:

```bash
git clone https://github.com/Vadims06/bmpwatcher.git && cd bmpwatcher
cp .env.example .env
docker compose --profile collector up -d
```

Defina no `.env`:

- `TOPOLOGRAPH_HOST`: o endereço IP do host Docker, não `localhost`, porque o Topolograph e o BMP Watcher rodam em suas próprias redes de contêineres; `topolograph.com` para a instância pública.
- `TOPOLOGRAPH_PORT`: `8080` por padrão, `443` para topolograph.com.
- `WEBHOOK_TLS_ON`: `off` para um Topolograph self-hosted, `on` para topolograph.com.
- `TOPOLOGRAPH_API_TOKEN`: o token `sk-...`.
- `SOURCE_ID`: o nome deste coletor no Topolograph, por exemplo `dc1-rr`. Mantenha-o estável: um contêiner recriado com o mesmo nome mantém seus dados juntos.
- `BMPWATCHER_LOG_DIR`: onde o coletor grava seus arquivos, `/var/log/bmpwatcher` por padrão.

Pare-o com o mesmo perfil: `docker compose --profile collector down`. Habilite o Docker na inicialização (`systemctl enable docker`): os contêineres voltam após uma falha e um reboot.

O primeiro snapshot sai quando cada roteador terminou de enviar sua tabela: cerca de 30 segundos depois que suas rotas param de chegar, no máximo 5 minutos após a primeira. Verifique se foi enviado:

```bash
docker logs bmpwatcher 2>&1 | grep 'topology posted'
```

### EVPN: primeiras mensagens

*Topolograph v2.73 ou posterior, BMP Watcher v1.1.0 ou posterior. A exportação EVPN foi verificada no FRR.*

As perguntas de EVPN são respondidas no seu grafo OSPF ou IS-IS, então o
Topolograph precisa de um grafo cujos Router IDs coincidam com os BGP speakers.

1. **Obtenha o grafo IGP.** Para a sua rede, faça upload do LSDB ou rode o
   [OSPF Watcher](ospf-watcher.md) / [IS-IS Watcher](isis-watcher.md). Para o
   laboratório [13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp), o underlay OSPF é o grafo de
   demonstração de 13 roteadores que o Topolograph cria em toda conta no
   primeiro login; para IS-IS, faça upload de [demo_isis_LSDB.txt](https://github.com/Vadims06/topolograph/blob/master/demo_isis_LSDB.txt) como
   FRR IS-IS.
2. **Ative o BMP nos route reflectors**: eles têm as rotas EVPN de todos os
   leaves, enquanto um leaf exporta só o que aprendeu. O FRR carrega o BMP como
   módulo, então adicione `-M bmp` a `bgpd_options` e reinicie o FRR:

```
# /etc/frr/daemons
bgpd_options="   --daemon -M bmp -A 127.0.0.1"
```

```
router bgp 65000
 bmp targets topolograph
  bmp connect 198.51.100.10 port 11019 min-retry 1000 max-retry 2000
  bmp monitor l2vpn evpn pre-policy
  bmp monitor l2vpn evpn post-policy
```

No containerlab, edite o arquivo `daemons` do laboratório e recrie o laboratório:
reiniciar o FRR dentro de um contêiner em execução derruba os links dele. Em
`bmp connect` use um endereço do host do coletor que os roteadores alcancem na porta
TCP 11019; no containerlab é o gateway da rede de gerência do laboratório
(`docker network inspect <mgmt-network>`).

3. **Inicie o coletor** como acima.
4. **Confira a resposta no grafo IGP**: o grafo cujos `protocols` incluem
   `bgp`, seus VNIs e VRFs, e os leaves de um VNI.

```bash
TOPOLOGRAPH_URL=http://<host-ip>:8080   # https://topolograph.com para a instância pública
curl -sS "$TOPOLOGRAPH_URL/api/graph/?protocol=bgp" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
curl -sS "$TOPOLOGRAPH_URL/api/graph/<graph_time>/vpns" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
curl -sS "$TOPOLOGRAPH_URL/api/graph/<graph_time>/nodes?protocol=bgp&vni=<vni>" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
```

Uma lista `?protocol=bgp` vazia significa que o grafo BGP ainda não foi
vinculado: confira `GET /api/bgp-graph/<bgp_graph_time>/bindings`. A tabela
inicial chega no snapshot; o fluxo de eventos traz só as mudanças posteriores.

Toda conta tem um grafo BGP de demonstração capturado no
laboratório 13-hosts-demo-bgp e vinculado ao mesmo grafo de demonstração, então nesse
grafo as respostas incluem também as rotas de demonstração.

---

## Vinculação aos seus grafos IGP

Após cada gravação BGP **e** cada gravação IGP, o Topolograph reavalia a quais
grafos OSPF ou IS-IS um grafo BGP pertence. Os candidatos são ordenados pela
sobreposição de Router IDs usando cobertura de conjuntos gulosa, então um grafo
BGP que abrange dois domínios IGP se vincula aos dois.

| Estado | Significado |
|---|---|
| `bound` | sobreposição de Router IDs ≥ 80 %, sem ambiguidade |
| `needs_mapping` | abaixo do limiar, ou dois candidatos empatados - aguardando confirmação |

Um grafo BGP se vincula primeiro ao grafo IGP que estava em vigor no seu
próprio momento: o mais recente que não seja posterior ao grafo BGP. Snapshots
IGP tirados depois, enquanto ele ainda é o grafo BGP mais recente da sua fonte,
também são vinculados, desde que mantenham os roteadores encontrados na primeira
correspondência. Um roteador que entrou depois do snapshot IGP é contado pelos
seus eventos de adjacência OSPF.

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
    anuncia nenhum não contribui para a pontuação de sobreposição - o que é o
    resultado honesto, não um defeito. Habilite TE no dispositivo ou defina o
    Router ID à mão na página de **mapeamento de hostnames**; a partir daí ele
    migra para os grafos seguintes como um hostname.

---

## Consultando os dados BGP

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
próprio speaker - e não de `AS_PATH[0]`, que uma rota refletida tornaria
enganoso.

### Busca de rotas

```bash
GET /api/bgp-graph/{bgp_graph_time}/routes?prefix=192.0.2.0/24
GET /api/bgp-graph/{bgp_graph_time}/node/{router_id}/routes?evidence=loc_rib
```

| Parâmetro | Comportamento |
|---|---|
| `prefix=192.0.2.0/24` | correspondência exata do prefixo completo |
| `prefix=192.0.2.5` | contenção: todas as rotas que cobrem o endereço, o prefixo mais longo primeiro |
| `mac`, `vni` | só EVPN, veja [EVPN](#evpn) |
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
queda de sessão - volume baixo, e cada flap importa - enquanto `bgp_route` é
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
2. **Seleção de melhor caminho BGP** - um caminho por prefixo, por LOCAL_PREF,
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
Métricas de OSPF, IS-IS e BGP nunca são comparadas entre si - uma métrica só faz
sentido dentro do seu próprio protocolo. iBGP versus eBGP é decidido pela sessão
em que a rota foi aprendida, não por `AS_PATH[0]`.

As rotas candidatas são limitadas ao que o nó inicial realmente enxerga: a sua
própria tabela reportada mais as tabelas dos seus vizinhos diretos de sessão. Um
roteador que não roda BGP não herda nada.

## EVPN

*Topolograph v2.73 ou posterior, BMP Watcher v1.1.0 ou posterior.*

BGP EVPN sobre VXLAN (AFI 25 / SAFI 70) é lido do fluxo BMP dos route
reflectors. Toda pergunta de EVPN é feita ao seu grafo OSPF ou IS-IS: o grafo
BGP vinculado a ele responde, e cada VTEP é resolvido para o roteador dono do
endereço, então um caminho até um host termina no leaf por trás dele.

### Tipos de rota

| Tipo de rota | RFC | Usado para |
|---|---|---|
| 1 Ethernet Auto-Discovery | [RFC 7432](https://datatracker.ietf.org/doc/html/rfc7432) | armazenada e pesquisável |
| 2 MAC/IP Advertisement | RFC 7432 | onde está um host: MAC, IP, VNI, VTEP, ESI; movimentos de MAC |
| 3 Inclusive Multicast Ethernet Tag | RFC 7432, [RFC 6514](https://datatracker.ietf.org/doc/html/rfc6514) | quais leaves são VTEPs de um VNI (o VNI vem do atributo PMSI Tunnel) |
| 4 Ethernet Segment | RFC 7432 | armazenada e pesquisável |
| 5 IP Prefix | [RFC 9136](https://datatracker.ietf.org/doc/html/rfc9136) | sub-redes de uma VRF e seu L3VNI |

### Atributos da rota

Uma rota EVPN traz os habituais RD, route targets, next hop e communities, além
de um objeto `evpn`:

| Campo | Significado |
|---|---|
| `route_type` | de 1 a 5 |
| `mac` | MAC do host (RT-2) |
| `ip`, `ip_len` | IP do host (RT-2), prefixo e seu comprimento (RT-5), roteador de origem (RT-3, RT-4) |
| `vni` | L2VNI (RT-2, RT-3) |
| `l3vni` | L3VNI da VRF (RT-5, e RT-2 com symmetric IRB) |
| `esi` | Ethernet Segment ID; só zeros significa host ligado a um único leaf |
| `eth_tag` | Ethernet Tag ID |
| `vtep` | o VTEP: o roteador de origem para RT-3 e RT-4, o next hop para os demais |
| `mm_seq` | número de sequência de MAC Mobility ([RFC 7432 §15](https://datatracker.ietf.org/doc/html/rfc7432#section-15)) |

Em RT-2 e RT-5 `prefix` também é preenchido (o endereço do host em /32 ou /128,
ou o prefixo RT-5), então `prefix=` encontra hosts e sub-redes EVPN como
qualquer outra rota.

```json
{
  "afi": 25, "safi": 70, "rd": "1:123.123.31.31:5",
  "route_targets": ["65000:1020"], "nexthop": "123.123.31.31",
  "evpn": {"route_type": 2, "mac": "00:c1:ab:00:00:03", "ip": null, "ip_len": null,
           "vni": 1020, "l3vni": null, "esi": "00:00:00:00:00:00:00:00:00:00",
           "eth_tag": 0, "vtep": "123.123.31.31", "mm_seq": null}
}
```

### Perguntas que responde

Todas são feitas ao grafo IGP (`{graph_time}`), sem o tempo do grafo BGP.

| Pergunta | Requisição |
|---|---|
| Quais VNIs e VRFs a fabric tem? | `GET /api/graph/{graph_time}/vpns` |
| Quais VPNs um roteador vê? | `GET /api/graph/{graph_time}/node/{router_id}/vpns` |
| Quais leaves carregam o VNI 1020 ou a VRF tenant1? | `GET /api/graph/{graph_time}/nodes?protocol=bgp&vni=1020` (ou `vrf=tenant1`) |
| Onde está um host: leaf, VNI, VRF, MAC? | `GET /api/graph/{graph_time}/routes?prefix=10.10.20.13` ou `?mac=00:c1:ab:00:00:03` |
| O host é multihomed? | a mesma requisição: vários VTEPs com um mesmo `esi` diferente de zero |
| O que uma VRF roteia? | `GET /api/graph/{graph_time}/routes?vrf=tenant1` |
| O que um leaf tem para um VNI? | `GET /api/graph/{graph_time}/node/{router_id}/routes?vni=1010` |
| Um MAC se moveu, de qual leaf para qual, quando? | `GET /api/events/{graph_time}/routes?mac=00:c1:ab:00:00:01&last_minutes=60` |
| Como o underlay alcança todos os VTEPs de um VNI? | `GET /api/graph/{graph_time}/path/{node_a}/{vtep1},{vtep2}` |

`routes` também aceita `at=` para um momento passado, e `vtep=`, `rt=`, `rd=`,
`page`, `per_page`. No histórico de eventos, a linha em que um MAC aparece num
novo VTEP traz `moved_from_vtep`. O mesmo MAC anunciado por vários VTEPs com um
mesmo ESI é multihoming, não um movimento.

Uma linha de VPN agrupa rotas pelo nome da VRF quando o inventário de VRFs o
conhece, senão pelo route target; um bridge domain EVPN é uma linha por L2VNI:

```json
{"name": null, "vni": 1020, "l3vni": 5000,
 "route_targets": ["65000:1020", "65000:5000"],
 "route_distinguishers": ["1:123.123.30.30:5", "1:123.123.31.31:5"],
 "prefix_count": 4}
```

Na interface, as mesmas respostas estão no formulário de caminho BGP / VPN e em
Graph table, BGP Routes, que tem colunas para cada campo acima. Um passo a passo
com os dados de demonstração está no [BGP how-to](https://topolograph.com/how-to/bgp#evpn), e o laboratório em
que foram capturados é [containerlab/13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp).

---

## Limites atuais

- EVPN assume VNIs globais em toda a fabric: VNIs de significado local
  (RFC 8365) não são suportados.
- Qual leaf é o designated forwarder de um Ethernet Segment é decidido nos
  próprios leaves e não é transportado por BMP.
- Um Router ID que legitimamente aparece em dois domínios IGP vinculados é
  resolvido para um deles na classificação de sessões.

---

## Veja também

- [bmpwatcher no GitHub](https://github.com/Vadims06/bmpwatcher)
- [OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)
- [Eventos, Linha do Tempo e Status](events-timeline.md)
- [Sessão BGP-LS](../ingestion/bgp-ls.md) - BGP-LS transporta topologia *IGP*,
  um assunto diferente do estado de roteamento BGP desta página

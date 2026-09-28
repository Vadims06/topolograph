# Fornecedores suportados

O Topolograph constrói um grafo a partir da Link-State Database de um único
dispositivo. Use os comandos abaixo para capturar a LSDB e depois
[envie-a](../ingestion/text-file.md).

## OSPF (OSPFv2)

| Fornecedor | LSA 1 (router) | LSA 2 (network) | LSA 5 (external) | Flags de nó (ABR/ASBR) | Driver SSH do SDK |
| --- | --- | --- | --- | :---: | :---: |
| Cisco | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ | ✅ |
| Cisco NX-OS | `show ip ospf database router detail` | `show ip ospf database network detail` | `show ip ospf database external detail` | ✅ | ✅ |
| Quagga | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ | ✅ |
| Ruckus | `show ip ospf database link-state router` | `show ip ospf database link-state network` | `show ip ospf database external-link-state` | | ✅ |
| Juniper | `show ospf database router extensive \| no-more` | `show ospf database network extensive \| no-more` | `show ospf database external extensive \| no-more` | ✅ | ✅ |
| Bird | `show ospf state all` | `show ospf state all` | `show ospf state all` | | ✅ |
| Nokia | `show router ospf database type router detail` | `show router ospf database type network detail` | `show router ospf database type external detail` | | ✅ |
| MikroTik | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` | ✅[^mt-flags] | ✅ |
| Huawei | `display ospf lsdb router` | `display ospf lsdb network` | `display ospf lsdb ase` | ✅ | ✅ |
| Palo Alto | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | | ✅ |
| Ubiquiti[^ubnt] | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | | ✅ |
| Allied Telesis | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | | ✅ |
| Extreme | `show ospf lsdb detail lstype router` | `show ospf lsdb detail lstype network` | `show ospf lsdb detail lstype as-external` | | ✅ |
| Ericsson | `show ospf database router detail` | `show ospf database network detail` | `show ospf database external detail` | | ✅ |
| Fortinet | `get router info ospf database router lsa` | `get router info ospf database network lsa` | `get router info ospf database external lsa` | | ✅ |
| FRRouting | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` | ✅ | ✅ |

[^ubnt]: Aplica-se à linha EdgeRouter e a gateways UniFi USG mais antigos. Os
    gateways UniFi mais novos usam o projeto [FRRouting](https://frrouting.org).

[^mt-flags]: RouterOS 7.18 ou mais recente, que imprime o campo `bits=` no
    dump da LSA.

!!! info "Flags de nó (ABR/ASBR)"
    Roteadores que anunciam o bit B (Area Border Router) ou E (AS Boundary
    Router) em sua Router-LSA são detectados e exibidos na tooltip do nó ao
    passar o mouse. A flag também é consultável na API de nós (`?abr=1`,
    `?asbr=1`). As mesmas flags são reportadas em tempo real pelo
    [OSPF Watcher](../monitoring/ospf-watcher.md).

!!! tip "Dados opcionais de TE (FRRouting)"
    Adicione `show ip ospf database opaque-area` ao mesmo arquivo para obter
    dados de largura de banda, métrica de TE e admin group. O grafo ainda é
    construído apenas com as LSAs 1/2/5. Veja
    [Traffic Engineering](../analysis/traffic-engineering.md).

## OSPFv3

| Fornecedor | Comando | Rede stub | External (redistribuída) |
| --- | --- | :---: | :---: |
| Arista | `show ipv6 ospf database detail` | ✅ | ✅ |
| IP Infusion OcNOS | `show ipv6 ospf database router`, `network`, `external`, `intra-prefix` | ✅ | ✅ |
| Fortinet FortiOS | `get router info6 ospf database router`, `network`, `external`, `intra-prefix` | ✅ | ✅ |
| MikroTik RouterOS | `/routing/ospf/lsa/print detail without-paging where instance=v3` | ✅ | ✅ |

!!! note
    OcNOS e FortiOS exigem as formas por tipo de LSA: `show ipv6 ospf database` / `get router info6 ospf database` sem tipo exibe apenas uma tabela de índice, e `intra-prefix` é obrigatório porque o OSPFv3 transporta prefixos somente nesse LSA.

## IS-IS

| Fornecedor | Comando | Rede stub | External (redistribuída) | Flags de nó (OL/ATT) |
| --- | --- | --- | --- | :---: |
| Cisco | `show isis database detail` | ✅ | Ainda não (precisa de um exemplo de LSDB) | ✅ |
| Juniper | `show isis database extensive` | ✅ (precisa de um exemplo de LSDB para confirmar) | Ainda não (precisa de um exemplo de LSDB) | ✅ (precisa de um exemplo de LSDB para confirmar) |
| Nokia | `show router isis database detail` | ✅ (precisa de um exemplo de LSDB para confirmar) | Ainda não (precisa de um exemplo de LSDB) | ✅ (precisa de um exemplo de LSDB para confirmar) |
| Huawei | `display isis lsdb verbose` | ✅ (precisa de um exemplo de LSDB para confirmar) | Ainda não (precisa de um exemplo de LSDB) | ✅ (precisa de um exemplo de LSDB para confirmar) |
| ZTE | `show isis database verbose` | ✅ (precisa de um exemplo de LSDB para confirmar) | Ainda não (precisa de um exemplo de LSDB) | ✅ (precisa de um exemplo de LSDB para confirmar) |
| FRRouting | `show isis database detail` | ✅ | Ainda não (precisa de um exemplo de LSDB) | ✅ |
| IP Infusion OcNOS | `show isis database verbose` | ✅ | ✅ | ✅ |
| Fortinet FortiOS | `get router info isis database detail` | ✅ | ✅ | ✅ (precisa de um exemplo de LSDB para confirmar) |
| MikroTik RouterOS | `/routing/isis/lsp/print detail without-paging` | ✅ | ✅ | |

!!! info "Flags de nó (overload / attached)"
    Overload (OL) e attached (ATT) são lidos a partir da coluna
    `ATT/P/OL` de cada LSP no envio de arquivo de texto, e também são
    reportados em tempo real pelo
    [IS-IS Watcher](../monitoring/isis-watcher.md) (que também deriva
    ABR/ASBR via BGP-LS).

!!! info "Tem um caso não suportado?"
    Vários cenários de IS-IS estão marcados como "precisa de um exemplo de LSDB" — se você puder compartilhar uma amostra da base de dados, o
    suporte pode ser adicionado. Abra uma issue no repositório
    correspondente.

## Suporte a TLVs do IS-IS { #is-is-tlv-support }

O parser de IS-IS (usado pelo Topolograph e pelo
[IS-IS Watcher](../monitoring/isis-watcher.md)) entende os seguintes TLVs:

| TLV | # | RFC | Cisco | Juniper | Nokia | FRR | Huawei | ZTE | MikroTik |
| --- | :-: | --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| IS Reachability | 2 | ISO 10589 | ✅ | ✅ | ✅ | ✅ |  | ✅ | ✅ |
| Extended IS Reachability (new) | 22 | RFC 5305 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv4 Internal Reachability (old) | 128 | RFC 1195 | ✅ | ✅ | ✅ | ✅ | ✅ |  | ✅ |
| IPv4 External Reachability (old) | 130 | RFC 1195 |  |  |  |  |  |  |  |
| Extended IPv4 Reachability (new) | 135 | RFC 5305 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv6 Reachability | 236 | RFC 5308 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Tanto métricas **narrow** (estilo antigo) quanto **wide** (estilo novo) são
interpretadas. Métricas wide carregam atributos de TE — veja
[Traffic Engineering](../analysis/traffic-engineering.md).

## Atributos de TE por fornecedor { #te-attributes-by-vendor }

O que o parser de cada fornecedor converte em atributos de enlace. Uma célula em branco significa que o atributo não é lido dessa saída, mesmo que o roteador o anuncie. Uma sessão de [Watcher](../monitoring/isis-watcher.md) ou BGP-LS transporta todos os atributos que o roteador anuncia.

### IS-IS { #te-is-is }

| Atributo de TE | Nome na API/SDK | Definido em | FRR | Nokia | ZTE | OcNOS |
| --- | --- | --- | :-: | :-: | :-: | :-: |
| Métrica padrão de TE | `temetric` | RFC 5305 §3.7, sub-TLV 18 | ✅ | ✅ |  | ✅ |
| Grupo administrativo | `admin_group` | RFC 5305 §3.1, sub-TLV 3 | ✅ | ✅ | ✅ |  |
| Largura de banda máxima do enlace | `max_link_bw` | RFC 5305 §3.4, sub-TLV 9 | ✅ | ✅ | ✅ |  |
| Largura de banda máxima reservável | `max_rsrv_link_bw` | RFC 5305 §3.5, sub-TLV 10 | ✅ | ✅ | ✅ |  |
| Largura de banda não reservada (por prioridade) | `unreserved_bw_0` … `unreserved_bw_7` | RFC 5305 §3.6, sub-TLV 11 | ✅ | ✅ | ✅ |  |
| Shared risk link group | `srlg` | RFC 5307 §1.2, TLV 138 | ✅ |  |  |  |
| Endereço da interface / do vizinho | `local_ip_address`, `remote_ip_address` | RFC 5305 §3.2, §3.3, sub-TLVs 6 / 8 | ✅ | ✅ | ✅ |  |
| ID local / remoto do enlace | `link_local_id`, `link_remote_id` | RFC 5307 §1.1, sub-TLV 4 |  |  | ✅ |  |

Comandos que exibem os sub-TLVs: `show isis database detail` (FRR), `show router isis database detail` (Nokia SR OS), `show isis database verbose` (ZTE, IP Infusion OcNOS). O OcNOS exibe os sub-TLVs de TE apenas com `verbose`, não com `detail`.

!!! note
    O FRR exibe o SRLG apenas em builds que incluem [FRRouting/frr#22392](https://github.com/FRRouting/frr/pull/22392).

### OSPF { #te-ospf }

| Atributo de TE | Nome na API/SDK | Definido em | FRR | OcNOS |
| --- | --- | --- | :-: | :-: |
| Métrica padrão de TE | `temetric` | RFC 3630 §2.5.5, sub-TLV 5 | ✅ | ✅ |
| Grupo administrativo | `admin_group` | RFC 3630 §2.5.9, sub-TLV 9 | ✅ |  |
| Largura de banda máxima do enlace | `max_link_bw` | RFC 3630 §2.5.6, sub-TLV 6 | ✅ |  |
| Largura de banda máxima reservável | `max_rsrv_link_bw` | RFC 3630 §2.5.7, sub-TLV 7 | ✅ |  |
| Largura de banda não reservada (por prioridade) | `unreserved_bw_0` … `unreserved_bw_7` | RFC 3630 §2.5.8, sub-TLV 8 | ✅ |  |
| Shared risk link group | `srlg` | RFC 4203 §1.3, sub-TLV 16 |  |  |
| Endereço da interface local / remota | `local_ip_address`, `remote_ip_address` | RFC 3630 §2.5.3, §2.5.4, sub-TLVs 3 / 4 | ✅ | ✅ |

Acrescente `show ip ospf database opaque-area` ao mesmo arquivo de upload. O OcNOS exibe a métrica de TE como `Admin Metric`.

## RFCs suportados { #supported-rfcs }

RFCs implementados nos parsers e nos cálculos do Topolograph.

| Protocolo | RFC | O que o Topolograph lê |
| --- | --- | --- |
| OSPFv2 | RFC 2328 | LSAs Router (1), Network (2) e AS-External (5) |
| OSPFv2 | RFC 3630 | Atributos de TE dos enlaces, a partir de LSAs opaque-area (tipo 10) |
| OSPFv2 | RFC 4203 | Shared risk link group (SRLG), quando os valores chegam de um Watcher |
| OSPFv2 | RFC 6987 | Flag de stub router (max-metric) nos nós |
| OSPFv3 | RFC 5340 | LSAs Router, Network, AS-External e Intra-Area-Prefix |
| IS-IS | ISO/IEC 10589 | IS Reachability (TLV 2), bancos Level 1 / Level 2, bits overload e attached |
| IS-IS | RFC 1195 | IPv4 Internal Reachability (TLV 128) |
| IS-IS | RFC 5305 | Extended IS e IPv4 Reachability (TLVs 22, 135) e sub-TLVs de TE |
| IS-IS | RFC 5307 | Shared risk link group (TLV 138) e identificadores local / remoto do enlace |
| IS-IS | RFC 5308 | IPv6 Reachability (TLV 236) |
| MPLS TE | RFC 3209 | Prioridades de setup e holding no posicionamento CSPF de túneis LSP |
| BGP | RFC 4271, RFC 4456, RFC 4364 | Seleção do melhor caminho, route reflection e rotas VPN |
| BGP | RFC 7854, RFC 8671, RFC 9069 | BMP: Adj-RIB-In / Adj-RIB-Out e Loc-RIB |
| BGP | RFC 7432, RFC 9136, RFC 8365, RFC 6514 | EVPN: rotas MAC/IP, Inclusive Multicast, Ethernet Segment e IP Prefix sobre VXLAN |

## Ingestão via BGP-LS

Além de arquivos de texto, a topologia OSPF e IS-IS pode ser obtida ao vivo
via **BGP-LS**, usando o Watcher correspondente. Veja
[Sessão BGP-LS](../ingestion/bgp-ls.md).

---

O schema de API canônico e interativo está sempre disponível em `/api/ui/`
na sua instância.

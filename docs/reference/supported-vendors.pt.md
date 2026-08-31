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

## IS-IS

| Fornecedor | Comando | Rede stub | External (redistribuída) | Flags de nó (OL/ATT) |
| --- | --- | --- | --- | :---: |
| Cisco | `show isis database detail` | ✅ | Ainda não (precisa de uma LSDB testada) | ✅ |
| Juniper | `show isis database extensive` | ✅ (precisa de uma LSDB testada para confirmar) | Ainda não (precisa de uma LSDB testada) | ✅ (precisa de uma LSDB testada para confirmar) |
| Nokia | `show router isis database detail` | ✅ (precisa de uma LSDB testada para confirmar) | Ainda não (precisa de uma LSDB testada) | ✅ (precisa de uma LSDB testada para confirmar) |
| Huawei | `display isis lsdb verbose` | ✅ (precisa de uma LSDB testada para confirmar) | Ainda não (precisa de uma LSDB testada) | ✅ (precisa de uma LSDB testada para confirmar) |
| ZTE | `show isis database verbose` | ✅ (precisa de uma LSDB testada para confirmar) | Ainda não (precisa de uma LSDB testada) | ✅ (precisa de uma LSDB testada para confirmar) |

!!! info "Flags de nó (overload / attached)"
    Overload (OL) e attached (ATT) são lidos a partir da coluna
    `ATT/P/OL` de cada LSP no envio de arquivo de texto, e também são
    reportados em tempo real pelo
    [IS-IS Watcher](../monitoring/isis-watcher.md) (que também deriva
    ABR/ASBR via BGP-LS).

!!! info "Tem um caso não suportado?"
    Vários cenários de IS-IS estão marcados como "precisa de uma LSDB
    testada" — se você puder compartilhar uma amostra da base de dados, o
    suporte pode ser adicionado. Abra uma issue no repositório
    correspondente.

## Suporte a TLVs do IS-IS { #is-is-tlv-support }

O parser de IS-IS (usado pelo Topolograph e pelo
[IS-IS Watcher](../monitoring/isis-watcher.md)) entende os seguintes TLVs:

| TLV | # | Cisco | Juniper | Nokia | FRR | Huawei | ZTE |
| --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| IS Reachability | 2 | ✅ | ✅ | ✅ | ✅ | | ✅ |
| Extended IS Reachability (new) | 22 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv4 Internal Reachability (old) | 128 | ✅ | ✅ | ✅ | ✅ | ✅ | |
| IPv4 External Reachability (old) | 130 | | | | | | |
| Extended IPv4 Reachability (new) | 135 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv6 Reachability | 236 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Tanto métricas **narrow** (estilo antigo) quanto **wide** (estilo novo) são
interpretadas. Métricas wide carregam atributos de TE — veja
[Traffic Engineering](../analysis/traffic-engineering.md).

## Ingestão via BGP-LS

Além de arquivos de texto, a topologia OSPF e IS-IS pode ser obtida ao vivo
via **BGP-LS**, usando o Watcher correspondente. Veja
[Sessão BGP-LS](../ingestion/bgp-ls.md).

---

O schema de API canônico e interativo está sempre disponível em `/api/ui/`
na sua instância.

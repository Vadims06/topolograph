# Envio de arquivo de texto

A forma mais simples de trazer uma topologia para o Topolograph: copie o
banco de dados de estado de enlace de **um** roteador e cole-o (ou envie-o).
Sem agentes, sem túneis, nada que toque a rede em produção.

![Upload an LSDB text file and build short paths](../assets/text_file_and_short_paths.gif)

## Por que um roteador é suficiente

OSPF e IS-IS são protocolos de estado de enlace: todo roteador dentro de uma
área/nível mantém uma cópia **idêntica** do banco de dados da área. O
Topolograph reconstrói toda a topologia a partir dessa única cópia — então
você só precisa coletá-la uma vez, de um único dispositivo.

Para ver a rede em várias áreas, colete a saída de um **ABR** (Area Border
Router): ele contém a LSDB de todas as áreas às quais se conecta.

## 1. Colete o banco de dados

Execute os comandos de banco de dados de LSA/LSP para a sua plataforma e
salve a saída em um arquivo de texto simples. A matriz completa está abaixo;
veja [Fornecedores suportados](../reference/supported-vendors.md) para
detalhes de OSPFv3 e TLV do IS-IS.

=== "OSPF (OSPFv2)"

    | Fornecedor | LSA 1 (roteador) | LSA 2 (rede) | LSA 5 (externa) |
    | --- | --- | --- | --- |
    | Cisco | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |
    | Cisco NX-OS | `show ip ospf database router detail` | `show ip ospf database network detail` | `show ip ospf database external detail` |
    | Quagga | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |
    | Ruckus | `show ip ospf database link-state router` | `show ip ospf database link-state network` | `show ip ospf database external-link-state` |
    | Juniper | `show ospf database router extensive \| no-more` | `show ospf database network extensive \| no-more` | `show ospf database external extensive \| no-more` |
    | Bird | `show ospf state all` | `show ospf state all` | `show ospf state all` |
    | Nokia | `show router ospf database type router detail` | `show router ospf database type network detail` | `show router ospf database type external detail` |
    | MikroTik | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` | `/routing ospf lsa print detail file=lsa.txt` |
    | Huawei | `display ospf lsdb router` | `display ospf lsdb network` | `display ospf lsdb ase` |
    | Palo Alto | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` | `show routing protocol ospf dumplsdb` |
    | Ubiquiti[^ubnt] | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |
    | Allied Telesis | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |
    | Extreme | `show ospf lsdb detail lstype router` | `show ospf lsdb detail lstype network` | `show ospf lsdb detail lstype as-external` |
    | Ericsson | `show ospf database router detail` | `show ospf database network detail` | `show ospf database external detail` |
    | Fortinet | `get router info ospf database router lsa` | `get router info ospf database network lsa` | `get router info ospf database external lsa` |
    | FRRouting | `show ip ospf database router` | `show ip ospf database network` | `show ip ospf database external` |

    [^ubnt]: Aplica-se à linha EdgeRouter e a gateways UniFi USG mais antigos.
        Gateways UniFi mais novos usam o projeto [FRRouting](https://frrouting.org).

=== "OSPFv3"

    | Fornecedor | Comando |
    | --- | --- |
    | Arista | `show ipv6 ospf database detail` |

=== "IS-IS"

    | Fornecedor | Comando de banco de dados |
    | --- | --- |
    | Cisco | `show isis database detail` |
    | Juniper | `show isis database extensive` |
    | Nokia | `show router isis database detail` |
    | Huawei | `display isis lsdb verbose` |
    | ZTE | `show isis database verbose` |

Você pode colocar as seções LSA 1 / 2 / 5 (OSPF) em um único arquivo — o
Topolograph as analisa em conjunto.

!!! tip "Opcional: enlaces mais ricos com dados de TE"
    Para o OSPF do FRRouting, anexe `show ip ospf database opaque-area` ao
    mesmo arquivo para incluir largura de banda do enlace, métrica de TE e
    administrative group. O grafo ainda é construído sem isso. Veja
    [Traffic Engineering](../analysis/traffic-engineering.md).

## 2. Envie o arquivo

1. Abra o Topolograph (`http://localhost:8080/` para uma
   [instalação local](../getting-started/quickstart-docker.md)).
2. Inicie um envio de topologia e cole ou anexe seu arquivo de texto.
3. Selecione o **fornecedor** e o **protocolo** correspondentes (OSPF / IS-IS).
4. Envie. O Topolograph analisa o banco de dados e renderiza o grafo.

![Uploading an LSDB text file and building short paths](../assets/text_file_and_short_paths.gif)

O resultado é um **snapshot** — uma imagem congelada da rede no momento da
captura. Toda análise é executada sobre o snapshot, então nada do que você
tentar afeta a produção.

## 3. Compare estados ao longo do tempo

Envie outra captura mais tarde e o Topolograph pode **comparar** os dois
snapshots, destacando exatamente o que mudou — nós e enlaces
adicionados/removidos, mudanças de custo e redes que aparecem/desaparecem.
Veja [Comparando estados da rede](../analysis/comparing-states.md).

## Enviando via API em vez disso

Tudo que você pode colar, você também pode enviar via `POST`. O
[SDK em Python](../automation/python-sdk.md) encapsula isso — e pode até
coletar a LSDB dos seus dispositivos via SSH e enviá-la em uma única etapa:

```bash
topo ingest inventory.yaml --upload --url http://localhost:8080
```

```python
graph = topo.uploader.upload_raw(
    lsdb_text=raw_text,
    vendor="FRR",
    protocol="isis",
)
```

---

**Quer atualizações ao vivo em vez de snapshots?** Transmita a topologia com
uma sessão do Watcher via [GRE](gre.md) ou [BGP-LS](bgp-ls.md).

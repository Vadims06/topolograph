# Integração com Zabbix

Se o Zabbix é o seu sistema de referência para alertas, os Watchers podem
disparar **alarmes** sobre mudanças de topologia — um vizinho perdido, o
custo de um link de trânsito alterado, uma rede retirada — junto com o
restante do seu monitoramento.

!!! note "Requer o Logstash"
    O caminho do Zabbix usa o perfil padrão (Logstash). Ele **não** está
    disponível com o perfil Fluent Bit.

## O que gera alarme

O Watcher já vem com definições prontas do Zabbix em `docs/zabbix-ui/`.
Quatro hosts/itens (mesmo nome no host e no item) são esperados:

| Item | Dispara quando… |
| --- | --- |
| `ospf_neighbor_up_down` | Uma nova adjacência se forma, ou um dispositivo perde seu vizinho |
| `ospf_network_up_down` | Uma rede é anunciada ou retirada de um nó |
| `ospf_link_cost_change` | O custo de um link de trânsito (entre vizinhos ativos) muda |
| `ospf_stub_network_cost_change` | O custo de uma rede stub muda |

!!! info "Por que o custo do link de trânsito importa"
    Links de trânsito conectam vizinhos ativos, então uma mudança de custo
    ali pode alterar os caminhos reais/mais curtos que o seu tráfego segue
    — exatamente o tipo de mudança para a qual você quer um alarme.

O **IS-IS Watcher** fornece os itens equivalentes de IS-IS (vizinho
up/down, mudança de custo em links de trânsito, retirada de rede),
compartilhando o mesmo conjunto de templates.

## Configurando

1. Importe as definições de host/item/trigger do diretório
   `docs/zabbix-ui/` do Watcher para o seu servidor Zabbix.
2. Aponte a exportação do Watcher para o Zabbix (configurado através do
   pipeline do Logstash / `.env`).
3. Provoque uma mudança em um laboratório (ou aguarde uma real) e confirme
   que o alarme aparece no seu dashboard do Zabbix.

Depois de configurado, os alarmes de topologia ativos detectados pelo
Watcher aparecem no dashboard do Zabbix como qualquer outro problema, com
a visão de dados mais recentes expondo os valores do evento subjacente.

---

**Relacionado:** [ELK / Kibana](elk-kibana.md) · [Webhooks e Slack](webhooks.md) ·
[OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)

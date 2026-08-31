# Comparando estados da rede

Cada topologia que você envia é um **snapshot** — a rede congelada no
momento da captura. O Topolograph mantém seus snapshots ao longo do tempo,
o que significa que você pode colocar dois deles lado a lado e ver
*exatamente* o que mudou.

## O fluxo clássico

1. **Snapshot antes.** Envie a LSDB atual (ou deixe um
   [Watcher](../monitoring/index.md) manter os snapshots fluindo
   automaticamente).
2. **Faça sua mudança.** Por exemplo, redistribua rotas do BGP para o OSPF
   com um route-map e uma prefix-list, ajuste a métrica de um enlace ou
   adicione uma nova adjacência.
3. **Snapshot depois.** Envie a nova LSDB.
4. **Compare.** O Topolograph destaca as diferenças entre os dois estados.

Como cada envio tem um timestamp, você pode comparar quaisquer dois pontos
no tempo — não apenas os consecutivos.

## O que uma comparação mostra

- **Enlaces** que apareceram ou desapareceram entre os dois estados.
- **Mudanças de custo** em enlaces existentes.
- **Redes/prefixos** que foram adicionados ou retirados.
- **Nós** que entraram ou saíram da topologia.

Isso transforma "minha mudança fez o que eu esperava?" em uma resposta
visual e verificável — em vez de comparar a saída bruta de `show` a olho
nu.

## Combina bem com o monitoramento

Snapshots manuais de antes/depois são ótimos para mudanças planejadas. Para
mudanças *não planejadas*, um [Watcher](../monitoring/index.md) registra
continuamente cada transição, para que você possa voltar em uma linha do
tempo de estados e ver o que mudou e quando — e ser alertado por meio do
[ELK](../monitoring/elk-kibana.md), do [Zabbix](../monitoring/zabbix.md) ou
do [Slack](../monitoring/webhooks.md).

---

**Próximo:** [Construa topologias arbitrárias com YAML →](yaml-topologies.md)

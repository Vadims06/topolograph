# OSPF Watcher

O **OSPF Watcher** é uma ferramenta de monitoramento para mudanças de
topologia OSPF. Ele escuta passivamente o plano de controle do OSPF — via
[adjacência GRE](../ingestion/gre.md) ou [BGP-LS](../ingestion/bgp-ls.md) —
e registra cada mudança e/ou a exporta (via Logstash ou Fluent Bit) para o
**ELK**, o **Zabbix**, **WebHooks** e o painel de monitoramento do
**Topolograph**. Tudo é distribuído como contêineres, então ele inicia
rapidamente.

[:simple-github: vadims06/ospfwatcher](https://github.com/Vadims06/ospfwatcher){ .md-button }

![OSPF Watcher + Topolograph architecture with XDP rules](../assets/ospfwatcher_architecture.png)

## Eventos detectados

- Adjacência de vizinho OSPF **Up/Down**
- **Mudanças de custo** de enlace OSPF
- Redes OSPF **aparecendo/desaparecendo**
- **Atributos de TE** do OSPF (via LSA opaca ou BGP-LS): administrative
  group, largura de banda máxima do enlace, largura de banda máxima
  reservável, largura de banda não reservada, métrica padrão de TE e
  shared risk link group (SRLG)
- **Mudanças de papel de nó** do OSPF: um roteador se tornando (ou deixando
  de ser) um **ABR** (Area Border Router), um **ASBR** (AS Boundary
  Router), ou entrando/saindo do **max-metric** (RFC 3137 stub router —
  todos os enlaces de trânsito anunciados com a métrica máxima para
  desviar o tráfego de trânsito; o equivalente do OSPF ao overload bit do
  IS-IS)

![OSPF monitoring — new subnet event](../assets/ospf_monitoring_new_subnet.png)

![OSPF monitoring — metric change, old and new cost](../assets/ospf_monitoring_change_metric.png)

![OSPF monitoring — up/down link events on the timeline](../assets/ospf_monitoring_down_link.png)

## Conectando-o

A conexão em si é configurada em [Obtendo a topologia](../ingestion/index.md):

- [**Modo GRE**](../ingestion/gre.md) — o FRR forma uma adjacência OSPF via
  um túnel GRE. Um **filtro XDP para OSPF** garante que o Watcher
  permaneça somente-escuta.
- [**Modo BGP-LS**](../ingestion/bgp-ls.md) — o roteador exporta a
  topologia OSPF via BGP-LS; o GoBGP + o encaminhador alimentam o Watcher.
  Requer a imagem **`vadims06/ospf-watcher:v3.1.0`** ou mais recente.

!!! note "Compatibilidade"
    Mudanças de rede do OSPF aparecem no grafo do Topolograph a partir do
    [topolograph v2.27](https://github.com/Vadims06/topolograph/releases/tag/v2.27)
    ou posterior.

## Laboratório rápido (containerlab) { #quick-lab-containerlab }

Um laboratório pronto em `containerlab/frr01` permite observar mudanças de
OSPF sem nenhum hardware real:

```bash
./containerlab/frr01/prepare.sh
sudo clab deploy --topo ./containerlab/frr01/frr01.clab.yml
```

![OSPF Watcher container lab logs](../assets/ospfwatcher_containerlab.png)

Nesta configuração mínima, o Watcher imprime as mudanças de topologia em um
arquivo de texto. Adicione o Topolograph e/ou o ELK para visualizá-las e
pesquisá-las — veja a tabela de
[tamanhos de implantação](index.md#deployment-sizes).

!!! tip "Sem dispositivo? Modo de teste"
    Defina `TEST_MODE=True` para reproduzir uma LSDB de demonstração e
    eventos de exemplo (perda de adjacência, mudança de métrica) de ponta a
    ponta através do pipeline.

## Formato do log de eventos { #event-log-format }

Os eventos do Watcher são linhas simples separadas por vírgula. Um evento
de host (adjacência):

```text
2023-01-01T00:00:00Z,demo-watcher,host,10.10.10.4,down,10.10.10.5,01Jan2023_00h00m00s_7_hosts,0,1234,192.168.145.5
```

> `10.10.10.5` detectou que o host `10.10.10.4`, na interface com
> `192.168.145.5`, na área `0` / AS `1234`, ficou **down** no timestamp.

Um evento de mudança de métrica:

```text
2023-01-01T00:00:00Z,demo-watcher,network,192.168.13.0/24,changed,old_cost:10,new_cost:12,10.10.10.1,01Jan2023_00h00m00s_7_hosts,0.0.0.0,1234,internal,0
```

> `10.10.10.1` detectou que a métrica da rede stub interna
> `192.168.13.0/24` mudou de `10` para `12`.

Um evento de mudança de flag de nó:

```text
2023-01-01T00:00:00Z,demo-watcher,node,10.1.1.3,changed,attr:abr,old:0,new:1,10.1.1.3,01Jan2023_00h00m00s_7_hosts,0,1234
```

> `10.1.1.3` se anunciou como um **ABR** (`abr` `0` → `1`). Um evento é
> emitido para cada flag alterada (`abr`, `asbr`, `maxmetric` para o OSPF;
> `overload`, `attached` para o IS-IS). Entrar em max-metric também emite
> um evento `metric` por enlace, já que o custo de todo enlace de trânsito
> salta para o máximo.

Esses registros são o que o Logstash/Fluent Bit encaminham para o
[ELK](elk-kibana.md), o [Zabbix](zabbix.md) e os [Webhooks](webhooks.md).

## Modo somente-escuta (XDP) { #listen-only-mode-xdp }

No modo GRE, o Watcher executa uma instância real do FRR — então é crítico
que ele **nunca** possa injetar prefixos no seu domínio OSPF. Um **filtro
XDP** inspeciona toda mensagem OSPF que o FRR tenta enviar e descarta
qualquer coisa que anuncie mais do que a própria rede do túnel GRE do
Watcher.

![Wireshark before/after the XDP filter](../assets/xdp_lsa5_drop.png)

Por exemplo, se `8.8.8.8/32` fosse acidentalmente redistribuído no
Watcher, a LSA 5 é descartada pelo XDP e nunca chega à rede. A mesma
proteção se aplica a mensagens Database Description e a redes stub extras
na LSA 1.

Comandos úteis:

```bash
# Watch XDP drop logs
sudo cat /sys/kernel/debug/tracing/trace_pipe

# Confirm the XDP program is attached to the Watcher's interface
ip l show dev it-vhost1025      # look for "prog/xdp id ..."

# Enable / disable the filter
sudo docker run -it --rm -v ./:/home/watcher/watcher/ --cap-add=NET_ADMIN \
  -u root --network host vadims06/ospf-watcher:latest \
  python3 ./client.py --action enable_xdp --watcher_num <num>
```

## Solução de problemas

**Modo GRE** — confirme a adjacência:

```text
show ip ospf neighbor
```

Seu dispositivo deve aparecer como vizinho. Se não aparecer, execute o
script de diagnóstico do Watcher (veja a seção de solução de problemas do
repositório).

**Modo BGP-LS** — o Watcher envia para o Topolograph somente depois que a
sessão BGP fica ativa. Verifique:

```bash
docker logs watcher<num>-bgpls-ospf-bgplswatcher
docker exec -it watcher<num>-bgpls-ospf-bgplswatcher gobgp neighbor
docker exec -it watcher<num>-bgpls-ospf-bgplswatcher gobgp global rib -a ls
```

Veja [Sessão BGP-LS](../ingestion/bgp-ls.md#3-verify-the-bgp-ls-session)
para o fluxo completo de verificação.

---

**Relacionado:** [IS-IS Watcher](isis-watcher.md) ·
[ELK / Kibana](elk-kibana.md) · [Zabbix](zabbix.md) · [Webhooks](webhooks.md)

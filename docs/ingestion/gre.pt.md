# Sessão GRE

No **modo GRE**, um Watcher forma uma adjacência OSPF/IS-IS real com um dos
seus roteadores por meio de um **túnel GRE**, e então encaminha
passivamente cada mudança de estado de enlace para o Topolograph. Ao
contrário de um arquivo de texto, este é um feed *ao vivo* — o grafo e a
linha do tempo de eventos são atualizados conforme a rede muda.

O modo GRE funciona com praticamente qualquer roteador capaz de construir
um túnel GRE e rodar OSPF/IS-IS sobre ele, o que o torna a opção de
ingestão ao vivo mais amplamente compatível.

![Watcher architecture with GRE adjacency and XDP filter](../assets/ospfwatcher_architecture.png)

## Como funciona

- O Watcher executa uma instância do **FRR** dentro de um namespace de rede
  isolado.
- Esse FRR forma uma adjacência OSPF (ou IS-IS) com o seu roteador **por
  meio de um túnel GRE**.
- Uma vez adjacente, o roteador inunda sua LSDB para o Watcher como
  qualquer outro vizinho — e o Watcher transforma cada mudança em um evento
  para o Topolograph, ELK, Zabbix ou Slack.

!!! warning "O Watcher é passivo — e protegido"
    O Watcher é um participante **somente de escuta**. Um **filtro XDP para
    OSPF** inspeciona tudo o que a instância FRR tenta anunciar e descarta
    qualquer DB description ou LSUpdate que anuncie mais do que a própria
    rede do túnel GRE do Watcher. Isso garante que o Watcher nunca possa
    injetar prefixos inesperados no seu domínio OSPF. Veja
    [Modo somente-escuta](../monitoring/ospf-watcher.md#listen-only-mode-xdp).

Cada Watcher mantém todas as rotas e atualizações dentro do seu **próprio
namespace**, então ele nunca afeta o roteamento do host ou outros Watchers.

## 1. Configure o túnel no roteador

Construa um túnel GRE do dispositivo até o host que executa o Watcher. Um
exemplo Cisco:

```text
interface Tunnel0
 ip address <gre-tunnel-ip>
 tunnel mode gre
 tunnel source <router-ip>
 tunnel destination <host-ip>
 ip ospf network type point-to-point
```

Depois inclua a rede do túnel GRE na configuração OSPF/IS-IS do roteador
para que uma adjacência possa se formar através dela.

## 2. Configure o Watcher

Do lado do Watcher, a rede do túnel GRE é definida na configuração do FRR
(`quagga/config/ospfd.conf` para OSPF). Implantar o namespace de laboratório
do Watcher, por exemplo via containerlab, cria:

- um namespace de rede isolado para o Watcher e seu FRR,
- um par de interfaces tap conectando o Watcher ao host Linux,
- o **túnel GRE** dentro do namespace do Watcher,
- NAT para o tráfego GRE,
- os processos FRR + Watcher,
- o **filtro XDP para OSPF** vinculado à interface tap do Watcher.

Os passos exatos estão nos repositórios do Watcher:
[OSPF Watcher](https://github.com/Vadims06/ospfwatcher) ·
[IS-IS Watcher](https://github.com/Vadims06/isiswatcher).

!!! tip "Sem roteador disponível? Use o modo de teste"
    Defina `TEST_MODE=True` para alimentar um Watcher a partir de um arquivo
    de LSDB de demonstração estático e reproduzir mudanças de exemplo (perda
    de adjacência, mudança de métrica) — perfeito para testar o pipeline de
    ponta a ponta sem nenhum dispositivo. Também há um
    [laboratório containerlab](../monitoring/ospf-watcher.md#quick-lab-containerlab)
    pronto para uso.

## 3. Verifique a adjacência

Confirme que o FRR do Watcher vê seu roteador como vizinho:

Abra um console no FRR do Watcher e execute `vtysh`:

```text
docker exec -it <watcher-container> vtysh
```

```text
show ip ospf neighbor      # OSPF
show isis neighbor         # IS-IS
```

Seu dispositivo de rede deve aparecer na saída. Se não aparecer, o Watcher
inclui um script de diagnóstico — veja a seção de solução de problemas nas
páginas do [OSPF Watcher](../monitoring/ospf-watcher.md) /
[IS-IS Watcher](../monitoring/isis-watcher.md).

## GRE vs BGP-LS

O modo GRE precisa de um túnel e de uma adjacência IGP por ponto de
conexão. Se seus roteadores conseguem exportar a topologia via **BGP-LS**,
esse modo evita túneis completamente e escala com mais facilidade entre
áreas/níveis.

[:octicons-arrow-right-24: Compare com o BGP-LS](bgp-ls.md)

---

**Próximo:** veja o que o Watcher faz com o feed →
[OSPF Watcher](../monitoring/ospf-watcher.md) ·
[IS-IS Watcher](../monitoring/isis-watcher.md)

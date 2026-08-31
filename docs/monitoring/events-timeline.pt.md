# API de monitoramento: eventos, linha do tempo e status

Esta página é a referência para os **campos derivados** que a API REST do
Topolograph calcula para grafos monitorados: a linha do tempo de eventos
(waves), o `status` do grafo e o `object_status` do evento. Ela explica o
que cada valor calculado significa.

## Linha do tempo de eventos (waves)

A **linha do tempo de eventos** agrupa eventos de up/down de nós/hosts em
**waves** cronológicas, para que você possa narrar um incidente de rede
(por exemplo: "a instabilidade começou em T a partir do dispositivo X; uma
rajada de flapping do dispositivo Y; reconvergiu em T+n") sem examinar
centenas de eventos brutos. O agrupamento é calculado no servidor.

Disponível via API REST do Topolograph em:

```
GET /api/events/{graph_time}/adjacency/timeline
    ?last_minutes=<int>       (optional)
    ?start_time=<ISO8601>     (optional, e.g. 2025-06-30T20:00:00Z)
    ?end_time=<ISO8601>       (optional)
    ?page=<int>               (optional, default 1)
    ?per_page=<int>           (optional, default 20)
```

A lista `waves` é paginada; a resposta inclui um bloco `pagination`
(`page`, `per_page`, `total`, `total_pages`).

Eventos existem apenas para grafos monitorados por um watcher. A resposta
contém **apenas resumos de wave** (sem arrays de eventos aninhados). Para
obter os eventos individuais de uma wave, consulte novamente o endpoint da
API do Topolograph `GET /api/events/{graph_time}/adjacency` com o
`start_ts`/`end_ts` da wave.

## Como as waves são detectadas

Os eventos são colocados em uma única linha do tempo cronológica e
divididos em waves pelo tempo de silêncio entre eles: uma nova wave começa
quando o intervalo até o próximo evento excede
`gap_multiplier * median_gap_sec`. A **mediana** do intervalo é usada (não
a média) para que um único período longo de calmaria não distorça o
limiar.

| Campo | Significado |
|-------|---------|
| `gap_multiplier` | Multiplicador usado para dividir as waves (padrão `5`). |
| `median_gap_sec` | Mediana em segundos entre eventos consecutivos (resistente a rajadas). |

## Campos por wave

| Campo | Significado |
|-------|---------|
| `wave_number` | Índice sequencial da wave, começando em 1. |
| `start_ts` / `end_ts` | Timestamps ISO 8601 (`...Z`) do primeiro/último evento na wave. Reutilizáveis como `start_time`/`end_time` para obter os eventos da wave. |
| `duration_sec` | Segundos do primeiro ao último evento da wave. |
| `event_count` | Número de eventos na wave. |
| `distinct_devices` | Número de dispositivos únicos na wave. |
| `trigger_device` | O dispositivo do primeiro evento na wave. |
| `pattern` | Classificação da wave (veja abaixo). |
| `converged` | `true` se todo dispositivo que ficou down na wave se recupera (um up posterior) dentro da janela de tempo consultada. Uma recuperação após `end_time` não é visível, então uma wave pode aparecer como `converged: false` mesmo que a rede tenha se recuperado depois, fora da janela. |

## Padrões de wave { #wave-patterns }

`pattern` classifica uma wave pelo que aconteceu com o estado do
dispositivo. Ele espelha o `status` em nível de grafo da API do
Topolograph `GET /api/graph/{graph_time}/status`:

| `pattern` | Significado | Exemplo | Status de grafo relacionado |
|-----------|---------|---------|----------------------|
| `outage`  | Pelo menos um dispositivo permanece **down** ao final da wave (caiu e não voltou). | `R1 down` (sem up posterior); `R1 down, R2 down then up` (R1 ainda down) | `critical` |
| `flap`    | Tudo o que ficou down **voltou a ficar up** dentro da wave. Independente do número de dispositivos: 1 dispositivo down e depois up, ou 100 dispositivos cada um down e depois up, ambos são `flap`. | `R1 down then up`; `R1..R100 each down then up` | `warning` |
| `up`      | Apenas eventos de **up**, nada ficou down na wave (uma recuperação ou uma adjacência totalmente nova). | `R1 up`, `R2 up` | `ok` |

## Exemplo de resposta

```json
{
  "graph_time": "10May2025_17h03m00s_7_hosts_ospfwatcher",
  "watcher_name": "demo-watcher",
  "gap_multiplier": 5,
  "median_gap_sec": 10.0,
  "waves": [
    {
      "wave_number": 1,
      "start_ts": "2025-05-10T17:09:24.707000Z",
      "end_ts": "2025-05-10T17:11:27.707000Z",
      "duration_sec": 123.0,
      "event_count": 10,
      "distinct_devices": 6,
      "trigger_device": "10.1.1.3",
      "pattern": "outage",
      "converged": false
    }
  ],
  "pagination": { "page": 1, "per_page": 20, "total": 1, "total_pages": 1 }
}
```

## Status do grafo

A API do Topolograph `GET /api/graph/{graph_time}/status` retorna um
`status` geral para o grafo, calculado a partir de sua conectividade e
eventos. Este é o equivalente em nível de grafo do `pattern` de uma wave:

| `status` | Quando | `pattern` de wave relacionado |
|----------|------|------------------------|
| `critical` | O grafo está **desconectado**, ou um nó ficou down e **não** voltou (um down persistente). | `outage` |
| `warning` | O grafo está conectado, mas um nó ficou **down e depois up** (um flap), ou há eventos de rede down ou mudanças de custo de enlace. | `flap` |
| `ok` | Existem eventos, mas são **apenas de up** (recuperações de host/rede), ou não há eventos nenhum e o grafo está conectado. | `up` |
| `no_monitoring_data` | O grafo não é monitorado por um watcher, então não tem eventos. | n/a |

`status.details` também inclui:

| Campo | Significado |
|-------|---------|
| `is_monitored` | `true` se o grafo é alimentado por um watcher (apenas grafos monitorados têm eventos). |
| `is_connected` | `true` se o grafo de topologia está totalmente conectado. |
| `up_node_events` / `down_node_events` | Contagens de eventos de nó up / down desde que o grafo foi coletado. |
| `all_host_up_down_events` | Contagem de todos os eventos de host up/down (incluindo os recuperados). |
| `network_up_down_events` | Contagem de eventos de rede (sub-rede) up/down. |
| `adjacency_cost_change_events` | Contagem de mudanças de custo de enlace/adjacência (métrica alterada, não um down). |
| `top_unstable_devices` | Top-N `{device, event_count}` em ordem decrescente (os piores infratores). |

## `object_status` do evento

Eventos brutos (`/adjacency`, `/networks`) carregam um `object_status`
derivado da mudança de custo reportada pelo watcher:

| `object_status` | Significado |
|-----------------|---------|
| `down` | O custo mudou **para** `-1` (adjacência/rede ficou down). |
| `up` | O custo mudou **saindo de** `-1` (recuperada ou recém-aparecida). |
| `changed` | O custo mudou entre dois valores reais (mudança de métrica, não um down/up). |

Apenas eventos de host `up`/`down` alimentam as [waves](#wave-patterns);
eventos `changed` são mudanças de custo de enlace e são reportados
separadamente em `adjacency_cost_change_events`.

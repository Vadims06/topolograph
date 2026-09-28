# BMP Watcher

**BMP Watcher** приносит в Topolograph управляющую плоскость BGP: сессии
пиринга, маршруты, которые по ним передаются, контекст VPN и все изменения
того и другого.

Это пассивная станция [BMP](https://datatracker.ietf.org/doc/html/rfc7854).
Маршрутизаторы сами открывают к ней TCP-сессию и передают свой Adj-RIB-In.
Watcher не говорит на BGP, не поднимает пиринг и никогда не подключается к
маршрутизатору сам, поэтому не добавляет состояния BGP в наблюдаемую сеть.

!!! info "Состояние BGP хранится отдельно от графа IGP"
    Сессия BGP - это отношение управляющей плоскости, а не линк передачи
    данных. BGP хранится как отдельный граф со своим жизненным циклом и
    *привязывается* к графам OSPF и IS-IS, но никогда не смешивается с ними.
    Граф BGP работает и сам по себе, вообще без графа IGP.

---

## Что собирается

### Семейства адресов

| Семейство | AFI | SAFI | Тип события |
|---|---:|---:|---|
| IPv4 unicast | 1 | 1 | `prefix` |
| IPv6 unicast | 2 | 1 | `prefix` |
| VPNv4 | 1 | 128 | `l3vpn` |
| VPNv6 | 2 | 128 | `l3vpn` |
| EVPN | 25 | 70 | `evpn` |

VPN-маршрут уникален только вместе со своим Route Distinguisher, поэтому RD
входит в его идентичность. У маршрута EVPN префикса нет вовсе - он
идентифицируется компонентами NLRI по RFC 7432: тип маршрута, Ethernet Segment
ID, Ethernet Tag, MAC, IP.

### Сообщения BMP

| Сообщение BMP | Что с ним делает Topolograph |
|---|---|
| Route Monitoring | строит таблицу и все последующие изменения маршрутов |
| Peer Up | состояние сессии и BGP Identifier пира - Router ID, на который относятся события |
| Peer Down | разрыв сессии и withdraw на каждый маршрут, который нёс этот пир |
| Initiation / Termination | жизненный цикл сессии коллектора |
| Statistics Report | игнорируется - счётчики не являются состоянием маршрутизации |

### Потоки политик и уровень доказательности

Оба потока Adj-RIB-In хранятся раздельно, а там, где спикер поддерживает
[RFC 9069](https://datatracker.ietf.org/doc/html/rfc9069), поток Loc-RIB
сохраняется как третье, отдельное наблюдение:

| Поток | Evidence | Что означает |
|---|---|---|
| `pre` / `out-pre` | `pre_policy` | пир анонсировал маршрут; роутер мог его отбросить |
| `post` / `out-post` | `post_policy` | роутер принял маршрут - это кандидат |
| `loc-rib` | `loc_rib` | собственный выбор роутера - установленный лучший путь |
| `fib` | `fib` | присутствует в таблице форвардинга |

Они никогда не сливаются. Маршрут, увиденный только в pre-policy, **никогда**
не показывается как выбранный или установленный - ради этого различия оба
потока и существуют.

---

## Установка коллектора

Попробовать без реальной сети можно на containerlab-лабе [13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp) из репозитория bmpwatcher.

Коллектор - [**bmpwatcher**](https://github.com/Vadims06/bmpwatcher), опубликованный
как Docker-образ `vadims06/bmpwatcher:latest`: пассивная станция BMP, к которой маршрутизаторы
подключаются по TCP 11019, сам он к маршрутизаторам не подключается. Он отделяет
первоначальную выгрузку таблицы от последующих изменений. В его README описана
настройка BMP на стороне маршрутизатора для FRR, IOS-XR, Junos и SR OS.

Нужен аккаунт Topolograph: зарегистрируйтесь на topolograph.com или, в
self-hosted установке, войдите пользователем из её `.env` (`TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `TOPOLOGRAPH_WEB_API_PASSWORD`).
Создайте токен API: **API → Токен → Create Token**. Рабочее пространство определяется
по токену на сервере и никогда не берётся из тела запроса.

### Запуск через Docker Compose

Compose-файл репозитория bmpwatcher запускает коллектор и отправщик событий Fluent Bit вместе:

```bash
git clone https://github.com/Vadims06/bmpwatcher.git && cd bmpwatcher
cp .env.example .env
docker compose --profile collector up -d
```

Задайте в `.env`:

- `TOPOLOGRAPH_HOST`: IP-адрес хоста с Docker, не `localhost`, потому что Topolograph и BMP Watcher работают в своих сетях контейнеров; `topolograph.com` для публичного экземпляра.
- `TOPOLOGRAPH_PORT`: по умолчанию `8080`, `443` для topolograph.com.
- `WEBHOOK_TLS_ON`: `off` для своего Topolograph, `on` для topolograph.com.
- `TOPOLOGRAPH_API_TOKEN`: токен `sk-...`.
- `SOURCE_ID`: имя этого коллектора в Topolograph, например `dc1-rr`. Не меняйте его: контейнер, пересозданный с тем же именем, сохраняет свои данные вместе.
- `BMPWATCHER_LOG_DIR`: куда коллектор пишет свои файлы, по умолчанию `/var/log/bmpwatcher`.

Останавливается с тем же профилем: `docker compose --profile collector down`. Включите запуск Docker при загрузке (`systemctl enable docker`): контейнеры поднимутся после сбоя и перезагрузки.

Первый снимок уходит, когда каждый маршрутизатор выгрузил свою таблицу: примерно через 30 секунд после того, как его маршруты перестали приходить, и не позже чем через 5 минут после первого. Проверьте, что он отправлен:

```bash
docker logs bmpwatcher 2>&1 | grep 'topology posted'
```

### EVPN: первые сообщения

*Topolograph v2.73 или новее, BMP Watcher v1.1.0 или новее. Экспорт EVPN проверен на FRR.*

На вопросы про EVPN отвечает граф OSPF или IS-IS, поэтому в Topolograph нужен
граф, в котором Router ID совпадают с BGP-спикерами.

1. **Возьмите граф IGP.** Для своей сети загрузите LSDB или запустите
   [OSPF Watcher](ospf-watcher.md) / [IS-IS Watcher](isis-watcher.md). Для лабы
   [13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp) её OSPF-underlay - это демо-граф на 13 роутеров,
   который Topolograph создаёт в каждом аккаунте при первом входе; для IS-IS
   загрузите [demo_isis_LSDB.txt](https://github.com/Vadims06/topolograph/blob/master/demo_isis_LSDB.txt) как FRR IS-IS.
2. **Включите BMP на route reflector'ах**: на них есть EVPN-маршруты всех
   leaf, а leaf отдаёт только то, что узнал сам. FRR подключает BMP модулем,
   поэтому добавьте `-M bmp` в `bgpd_options` и перезапустите FRR:

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

В containerlab отредактируйте файл `daemons` лабы и пересоздайте лабу: перезапуск
FRR внутри работающего контейнера рвёт её линки. В `bmp connect` укажите адрес хоста
коллектора, до которого роутеры доходят по TCP 11019; в containerlab это шлюз
management-сети лабы (`docker network inspect <mgmt-network>`).

3. **Запустите коллектор**, как описано выше.
4. **Проверьте ответ на графе IGP**: граф, у которого в `protocols` есть
   `bgp`, его VNI и VRF, и leaf одного VNI.

```bash
TOPOLOGRAPH_URL=http://<host-ip>:8080   # https://topolograph.com для публичного экземпляра
curl -sS "$TOPOLOGRAPH_URL/api/graph/?protocol=bgp" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
curl -sS "$TOPOLOGRAPH_URL/api/graph/<graph_time>/vpns" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
curl -sS "$TOPOLOGRAPH_URL/api/graph/<graph_time>/nodes?protocol=bgp&vni=<vni>" -H "Authorization: Bearer $TOPOLOGRAPH_API_TOKEN"
```

Пустой список `?protocol=bgp` означает, что граф BGP ещё не привязан:
проверьте `GET /api/bgp-graph/<bgp_graph_time>/bindings`. Первоначальная
таблица приходит в снимке, а поток событий несёт только последующие изменения.

В каждом аккаунте есть демо-граф BGP, снятый с лабы
13-hosts-demo-bgp и привязанный к тому же демо-графу, поэтому на нём в ответах будут
и демо-маршруты.

---

## Привязка к графам IGP

После каждого сохранения BGP **и** каждого сохранения IGP Topolograph заново
вычисляет, каким графам OSPF или IS-IS принадлежит граф BGP. Кандидаты
ранжируются по пересечению Router ID жадным покрытием множества, поэтому граф
BGP, охватывающий два домена IGP, привязывается к обоим.

| Состояние | Значение |
|---|---|
| `bound` | пересечение Router ID ≥ 80 %, однозначно |
| `needs_mapping` | ниже порога или два равных кандидата - ждёт подтверждения |

Граф BGP сначала привязывается к графу IGP, который действовал в его момент
времени: самому позднему, не новее графа BGP. Снимки IGP, сделанные позже, пока
этот граф BGP остаётся самым новым для своего источника, тоже привязываются,
если в них остались роутеры первого совпадения. Роутер, появившийся после
снимка IGP, учитывается по событиям соседства OSPF.

Совпадение Router ID - **свидетельство, а не требование**. BGP Router ID и OSPF
Router ID обычно совпадают, но Topolograph на этом не настаивает: неоднозначные
результаты остаются видимыми для подтверждения вручную.

```bash
# к чему привязан граф BGP
curl -sS ".../api/bgp-graph/17Aug2026_09h12m03s_6_hosts/bindings" -H "Authorization: Bearer $T"

# подтвердить привязку вручную
curl -sS -X PUT ".../api/bgp-graph/<bgp_graph_time>/<igp_graph_time>/binding" -H "Authorization: Bearer $T"

# удалить
curl -sS -X DELETE ".../api/bgp-graph/<bgp_graph_time>/<igp_graph_time>/binding" -H "Authorization: Bearer $T"
```

!!! note "Для IS-IS нужен настоящий Router ID"
    Внутри узел IS-IS называется псевдо-Router ID, который придумал парсер и
    которого нет нигде в сети. Идентичностью считается только **TE Router ID**,
    анонсированный самим устройством. Устройство, которое его не анонсирует,
    не вносит вклада в оценку пересечения - это честный результат, а не ошибка.
    Включите TE на устройстве или задайте Router ID вручную на странице
    **сопоставления имён хостов**; дальше он переносится на следующие графы так
    же, как имя хоста.

---

## Запросы к данным BGP

### Графы, узлы и сессии

```bash
GET /api/bgp-graphs?page=1&per_page=50
GET /api/bgp-graph/{bgp_graph_time}
GET /api/bgp-graph/{bgp_graph_time}/nodes?role=rr&asn=65001
GET /api/bgp-graph/{bgp_graph_time}/sessions?igp_relation=inter-domain&bgp_session_type=ebgp
```

Каждая сессия классифицируется, как только известны привязки:

| `igp_relation` | Значение |
|---|---|
| `intra-domain` | оба конца в одном привязанном графе IGP |
| `inter-domain` | концы в двух разных привязанных графах IGP |
| `external` | хотя бы один конец не входит ни в один привязанный граф |

`bgp_session_type` - `ibgp` или `ebgp`, определяется по ASN сессии
относительно собственного ASN спикера, а не по `AS_PATH[0]`, который на
рефлектированном маршруте вводил бы в заблуждение.

### Поиск маршрутов

```bash
GET /api/bgp-graph/{bgp_graph_time}/routes?prefix=192.0.2.0/24
GET /api/bgp-graph/{bgp_graph_time}/node/{router_id}/routes?evidence=loc_rib
```

| Параметр | Поведение |
|---|---|
| `prefix=192.0.2.0/24` | точное совпадение по полному префиксу |
| `prefix=192.0.2.5` | вхождение - все маршруты, покрывающие адрес, сначала самый длинный префикс |
| `mac`, `vni` | только EVPN, см. [EVPN](#evpn) |
| `afi` / `safi` | числовое семейство |
| `rd` | Route Distinguisher |
| `vrf` | имя VRF, раскрывается в его RD через инвентарь |
| `rt` | любой Route Target маршрута |
| `policy` / `evidence` | исходный поток либо `pre_policy` / `post_policy` / `loc_rib` / `fib` |
| `as_path_contains` | подстрока в любом месте AS_PATH |
| `community` / `large_community` / `extended_community` | поиск по community |
| `origin`, `local_pref`, `med`, `originator_id`, `label` | фильтры по атрибутам |
| `peer_ip`, `nexthop`, `bmp_source` | кто анонсировал и как достигается |
| `page`, `per_page` | постраничный вывод (`per_page` не больше 500) |

Каждый маршрут несёт VRF/RD/RT, AFI/SAFI, политику и evidence, path ID,
community, next hop, метки и origin.

### История и сравнение

```bash
# состояние таблицы сейчас или на момент времени
GET /api/bgp-graph/{bgp_graph_time}/routes/state
GET /api/bgp-graph/{bgp_graph_time}/routes/state?at=2026-08-17T09:20:00Z

# что изменилось между двумя моментами
GET /api/bgp-graph/{bgp_graph_time}/routes/compare?t0=...&t1=...

# лента событий и дорожки таймлайна мониторинга
GET /api/bgp-graph/{bgp_graph_time}/events?last_minutes=60&event_name=peer
GET /api/bgp-graph/{bgp_graph_time}/events/timeline
```

`state` без `at` читает постоянно поддерживаемое текущее представление,
поэтому стоит размера ответа, а не проигрывания всего журнала событий. Явный
`at` проигрывает изменения от базового снимка до этого момента. Границы
интервала включаются с обеих сторон.

`compare` возвращает по строке на изменение: `added`, `withdrawn` или
`changed` с состоянием до и после.

На таймлайне мониторинга `bgp_peer` даёт по маркеру на каждое поднятие или
падение сессии - событий мало, и важно каждое, - а `bgp_route`
кластеризуется, поэтому всплеск маршрутного шума рисуется одним маркером со
счётчиком, а не тысячами точек.

### Route lookup

Route lookup отвечает на вопрос «что этот маршрутизатор реально сделает с этим
назначением», в отличие от чистого SPF по топологии.

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

Порядок принятия решения задан намеренно:

1. **Самый длинный совпадающий префикс** в выбранной таблице или VRF.
2. **Выбор лучшего пути BGP** - один путь на префикс, по LOCAL_PREF, длине
   AS_PATH, ORIGIN и MED, прежде чем что-либо начнёт сравнивать протоколы.
   Наблюдение Loc-RIB завершает сравнение: это собственный выбор роутера.
3. **Административная дистанция** между оставшимися кандидатами разных
   протоколов.
4. **Рекурсивное разрешение next hop** с защитой от петель и по глубине.
5. **Транспорт IGP SPF/CSPF** до этого next hop, при необходимости через
   подходящие LSP-шорткаты.

| Протокол | AD |
|---|---:|
| connected | 0 |
| static | 1 |
| eBGP | 20 |
| OSPF | 110 |
| IS-IS | 115 |
| iBGP | 200 |

Административная дистанция принадлежит **маршрутам**, а не рёбрам топологии.
Метрики OSPF, IS-IS и BGP никогда не сравниваются между собой - метрика имеет
смысл только внутри своего протокола. iBGP или eBGP определяется сессией, по
которой маршрут выучен, а не по `AS_PATH[0]`.

Кандидаты ограничены тем, что реально видит стартовый узел: его собственная
сообщённая таблица плюс таблицы его непосредственных соседей по сессиям.
Маршрутизатор без BGP не наследует ничего.

## EVPN

*Topolograph v2.73 или новее, BMP Watcher v1.1.0 или новее.*

BGP EVPN поверх VXLAN (AFI 25 / SAFI 70) читается из BMP-потока route
reflector'ов. Любой вопрос про EVPN задаётся графу OSPF или IS-IS: отвечает
привязанный к нему граф BGP, а каждый VTEP сопоставляется с роутером, которому
принадлежит адрес, поэтому путь к хосту заканчивается на leaf за ним.

### Типы маршрутов

| Тип маршрута | RFC | Для чего используется |
|---|---|---|
| 1 Ethernet Auto-Discovery | [RFC 7432](https://datatracker.ietf.org/doc/html/rfc7432) | хранится и ищется |
| 2 MAC/IP Advertisement | RFC 7432 | где хост: MAC, IP, VNI, VTEP, ESI; переезды MAC |
| 3 Inclusive Multicast Ethernet Tag | RFC 7432, [RFC 6514](https://datatracker.ietf.org/doc/html/rfc6514) | какие leaf являются VTEP для VNI (VNI берётся из атрибута PMSI Tunnel) |
| 4 Ethernet Segment | RFC 7432 | хранится и ищется |
| 5 IP Prefix | [RFC 9136](https://datatracker.ietf.org/doc/html/rfc9136) | подсети VRF и его L3VNI |

### Атрибуты маршрута

У маршрута EVPN есть обычные RD, route target, next hop и community, а также
объект `evpn`:

| Поле | Значение |
|---|---|
| `route_type` | от 1 до 5 |
| `mac` | MAC хоста (RT-2) |
| `ip`, `ip_len` | IP хоста (RT-2), префикс и его длина (RT-5), роутер-источник (RT-3, RT-4) |
| `vni` | L2VNI (RT-2, RT-3) |
| `l3vni` | L3VNI VRF (RT-5, а также RT-2 при symmetric IRB) |
| `esi` | Ethernet Segment ID; все нули - хост подключён к одному leaf |
| `eth_tag` | Ethernet Tag ID |
| `vtep` | VTEP: роутер-источник для RT-3 и RT-4, next hop для остальных |
| `mm_seq` | порядковый номер MAC Mobility ([RFC 7432 §15](https://datatracker.ietf.org/doc/html/rfc7432#section-15)) |

У RT-2 и RT-5 заполнен и `prefix` (адрес хоста с /32 или /128 либо префикс RT-5),
поэтому `prefix=` находит хосты и подсети EVPN так же, как любые другие маршруты.

```json
{
  "afi": 25, "safi": 70, "rd": "1:123.123.31.31:5",
  "route_targets": ["65000:1020"], "nexthop": "123.123.31.31",
  "evpn": {"route_type": 2, "mac": "00:c1:ab:00:00:03", "ip": null, "ip_len": null,
           "vni": 1020, "l3vni": null, "esi": "00:00:00:00:00:00:00:00:00:00",
           "eth_tag": 0, "vtep": "123.123.31.31", "mm_seq": null}
}
```

### На какие вопросы отвечает

Все они задаются графу IGP (`{graph_time}`), время графа BGP не нужно.

| Вопрос | Запрос |
|---|---|
| Какие VNI и VRF есть в фабрике? | `GET /api/graph/{graph_time}/vpns` |
| Какие VPN видит один роутер? | `GET /api/graph/{graph_time}/node/{router_id}/vpns` |
| Какие leaf несут VNI 1020 или VRF tenant1? | `GET /api/graph/{graph_time}/nodes?protocol=bgp&vni=1020` (или `vrf=tenant1`) |
| Где хост: leaf, VNI, VRF, MAC? | `GET /api/graph/{graph_time}/routes?prefix=10.10.20.13` или `?mac=00:c1:ab:00:00:03` |
| Подключён ли хост к нескольким leaf? | тот же запрос: несколько VTEP с одним ненулевым `esi` |
| Что маршрутизирует VRF? | `GET /api/graph/{graph_time}/routes?vrf=tenant1` |
| Что лежит на одном leaf для VNI? | `GET /api/graph/{graph_time}/node/{router_id}/routes?vni=1010` |
| Переезжал ли MAC, откуда, куда и когда? | `GET /api/events/{graph_time}/routes?mac=00:c1:ab:00:00:01&last_minutes=60` |
| Как underlay доходит до всех VTEP одного VNI? | `GET /api/graph/{graph_time}/path/{node_a}/{vtep1},{vtep2}` |

`routes` также принимает `at=` для момента в прошлом, а ещё `vtep=`, `rt=`,
`rd=`, `page`, `per_page`. В истории событий строка, где MAC появился на новом
VTEP, содержит `moved_from_vtep`. Один MAC от нескольких VTEP с одним ESI - это
multihoming, а не переезд.

Строка VPN группирует маршруты по имени VRF, если оно известно из инвентаря VRF,
иначе по route target; bridge domain EVPN - одна строка на L2VNI:

```json
{"name": null, "vni": 1020, "l3vni": 5000,
 "route_targets": ["65000:1020", "65000:5000"],
 "route_distinguishers": ["1:123.123.30.30:5", "1:123.123.31.31:5"],
 "prefix_count": 4}
```

В интерфейсе те же ответы есть в форме пути BGP / VPN и в Graph table, вкладка
BGP Routes, где для каждого поля выше есть колонка. Пошаговый разбор на
демо-данных - в [BGP how-to](https://topolograph.com/how-to/bgp#evpn), лаба, на которой они сняты, -
[containerlab/13-hosts-demo-bgp](https://github.com/Vadims06/bmpwatcher/tree/master/containerlab/13-hosts-demo-bgp).

---

## Текущие ограничения

- EVPN предполагает, что VNI едины для всей фабрики: локально значимые VNI
  (RFC 8365) не поддерживаются.
- Какой leaf является designated forwarder для Ethernet Segment, решают сами
  leaf, и по BMP это не передаётся.
- Router ID, который законно присутствует в двух привязанных доменах IGP, при
  классификации сессий относится к одному из них.

---

## Смотрите также

- [bmpwatcher на GitHub](https://github.com/Vadims06/bmpwatcher)
- [OSPF Watcher](ospf-watcher.md) · [IS-IS Watcher](isis-watcher.md)
- [События, таймлайн и статус](events-timeline.md)
- [Сессия BGP-LS](../ingestion/bgp-ls.md) - BGP-LS переносит топологию *IGP*,
  это другой предмет, чем состояние маршрутизации BGP на этой странице

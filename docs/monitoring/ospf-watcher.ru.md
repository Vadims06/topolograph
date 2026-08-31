# OSPF Watcher

**OSPF Watcher** - инструмент для мониторинга изменений топологии OSPF. Он
пассивно слушает control plane OSPF - через [соседство по GRE](../ingestion/gre.md)
или [BGP-LS](../ingestion/bgp-ls.md) - и логирует каждое изменение и/или
экспортирует его (через Logstash или Fluent Bit) в **ELK**, **Zabbix**,
**WebHooks** и на дашборд мониторинга **Topolograph**. Всё поставляется в
виде контейнеров, поэтому запускается быстро.

[:simple-github: vadims06/ospfwatcher](https://github.com/Vadims06/ospfwatcher){ .md-button }

![Архитектура OSPF Watcher + Topolograph с правилами XDP](../assets/ospfwatcher_architecture.png)

## Обнаруживаемые события

- **Подъём/разрыв** соседства с OSPF-соседом
- **Изменения метрики** линка OSPF
- **Появление/исчезновение** сетей OSPF
- **Атрибуты TE** OSPF (через opaque LSA или BGP-LS): административная
  группа, максимальная пропускная способность линка, максимальная
  резервируемая пропускная способность, нерезервированная пропускная
  способность, TE-метрика по умолчанию и shared risk link group (SRLG)
- **Изменения роли узла** OSPF: маршрутизатор становится (или перестаёт
  быть) **ABR** (Area Border Router), **ASBR** (AS Boundary Router) или
  входит/выходит из режима **max-metric** (stub-маршрутизатор по RFC 3137 - все транзитные линки анонсируются с максимальной метрикой, чтобы увести
  от них транзитный трафик; аналог бита overload в IS-IS для OSPF)

![Мониторинг OSPF - событие новой подсети](../assets/ospf_monitoring_new_subnet.png)

![Мониторинг OSPF - изменение метрики, старая и новая стоимость](../assets/ospf_monitoring_change_metric.png)

![Мониторинг OSPF - события подъёма/разрыва линка на временной шкале](../assets/ospf_monitoring_down_link.png)

## Подключение

Само подключение настраивается в разделе [Получение топологии](../ingestion/index.md):

- [**Режим GRE**](../ingestion/gre.md) - FRR устанавливает соседство OSPF
  через туннель GRE. **XDP-фильтр OSPF** гарантирует, что Watcher остаётся
  только слушателем.
- [**Режим BGP-LS**](../ingestion/bgp-ls.md) - маршрутизатор экспортирует
  топологию OSPF через BGP-LS; GoBGP + BGP-LS Watcher передают данные
  Watcher-у. Требуется образ **`vadims06/ospf-watcher:v3.1.0`** или новее.

!!! note "Совместимость"
    Изменения сетей OSPF отображаются на графе Topolograph начиная с
    [topolograph v2.27](https://github.com/Vadims06/topolograph/releases/tag/v2.27)
    и новее.

## Быстрая лаборатория (containerlab) { #quick-lab-containerlab }

Готовая лаборатория в `containerlab/frr01` позволяет наблюдать изменения
OSPF без реального оборудования:

```bash
./containerlab/frr01/prepare.sh
sudo clab deploy --topo ./containerlab/frr01/frr01.clab.yml
```

![Логи лаборатории containerlab OSPF Watcher](../assets/ospfwatcher_containerlab.png)

В этой минимальной конфигурации Watcher выводит изменения топологии в
текстовый файл. Добавьте Topolograph и/или ELK, чтобы визуализировать и
искать их - см. таблицу
[размеров развёртывания](index.md#deployment-sizes).

!!! tip "Нет устройства? Тестовый режим"
    Установите `TEST_MODE=True`, чтобы воспроизвести демонстрационную LSDB
    и примеры событий (потеря соседства, изменение метрики) через весь
    конвейер целиком.

## Формат журнала событий { #event-log-format }

События Watcher-а - это простые строки, разделённые запятыми. Событие хоста
(соседства):

```text
2023-01-01T00:00:00Z,demo-watcher,host,10.10.10.4,down,10.10.10.5,01Jan2023_00h00m00s_7_hosts,0,1234,192.168.145.5
```

> `10.10.10.5` обнаружил, что хост `10.10.10.4` на интерфейсе с
> `192.168.145.5`, в области `0` / AS `1234`, перешёл в состояние **down**
> в указанный момент времени.

Событие изменения метрики:

```text
2023-01-01T00:00:00Z,demo-watcher,network,192.168.13.0/24,changed,old_cost:10,new_cost:12,10.10.10.1,01Jan2023_00h00m00s_7_hosts,0.0.0.0,1234,internal,0
```

> `10.10.10.1` обнаружил, что метрика внутренней stub-сети
> `192.168.13.0/24` изменилась с `10` на `12`.

Событие изменения флага узла:

```text
2023-01-01T00:00:00Z,demo-watcher,node,10.1.1.3,changed,attr:abr,old:0,new:1,10.1.1.3,01Jan2023_00h00m00s_7_hosts,0,1234
```

> `10.1.1.3` анонсировал себя как **ABR** (`abr` `0` → `1`). На каждый
> изменённый флаг генерируется отдельное событие (`abr`, `asbr`,
> `maxmetric` для OSPF; `overload`, `attached` для IS-IS). Вход в режим
> max-metric также генерирует событие `metric` для каждого линка, поскольку
> стоимость каждого транзитного линка подскакивает до максимума.

Именно эти записи Logstash/Fluent Bit пересылают в
[ELK](elk-kibana.md), [Zabbix](zabbix.md) и [Webhooks](webhooks.md).

## Режим только для прослушивания (XDP) { #listen-only-mode-xdp }

В режиме GRE Watcher запускает настоящий экземпляр FRR - поэтому критически
важно, чтобы он **никогда** не мог внедрить префиксы в ваш домен OSPF.
**XDP-фильтр** проверяет каждое сообщение OSPF, которое FRR пытается
отправить, и отбрасывает всё, что анонсирует больше, чем собственная сеть
GRE-туннеля Watcher-а.

![Wireshark до/после применения XDP-фильтра](../assets/xdp_lsa5_drop.png)

Например, если бы `8.8.8.8/32` случайно перераспределили на Watcher-е,
LSA 5 будет отброшена XDP и никогда не достигнет сети. Та же защита
применяется к сообщениям Database Description и к лишним stub-сетям в
LSA 1.

Полезные команды:

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

## Устранение неполадок

**Режим GRE** - проверьте соседство:

```text
show ip ospf neighbor
```

Ваше устройство должно появиться в списке соседей. Если этого не
произошло, запустите диагностический скрипт Watcher-а (см. раздел
устранения неполадок в репозитории).

**Режим BGP-LS** - Watcher отправляет данные в Topolograph только после
установления сессии BGP. Проверьте это:

```bash
docker logs watcher<num>-bgpls-ospf-bgplswatcher
docker exec -it watcher<num>-bgpls-ospf-bgplswatcher gobgp neighbor
docker exec -it watcher<num>-bgpls-ospf-bgplswatcher gobgp global rib -a ls
```

Полный порядок проверки - в разделе
[Сессия BGP-LS](../ingestion/bgp-ls.md#3-verify-the-bgp-ls-session).

---

**Связанные страницы:** [IS-IS Watcher](isis-watcher.md) ·
[ELK / Kibana](elk-kibana.md) · [Zabbix](zabbix.md) · [Webhooks](webhooks.md)

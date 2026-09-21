# Поддерживаемые производители

Topolograph строит граф по LSDB одного устройства. Используйте команды ниже, чтобы получить
LSDB, а затем [загрузите её](../ingestion/text-file.md).

## OSPF (OSPFv2)

| Производитель | LSA 1 (router) | LSA 2 (network) | LSA 5 (external) | Флаги узла (ABR/ASBR) | SSH-драйвер SDK |
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

[^ubnt]: Применимо к линейке EdgeRouter и более старым шлюзам UniFi USG.
    Новые шлюзы UniFi используют проект [FRRouting](https://frrouting.org).

[^mt-flags]: RouterOS 7.18 и новее, где в дампе LSA выводится поле `bits=`.

!!! info "Флаги узла (ABR/ASBR)"
    Маршрутизаторы, анонсирующие бит B (Area Border Router) или E (AS
    Boundary Router) в своей Router-LSA, обнаруживаются и отображаются во
    всплывающей подсказке узла при наведении. Этот флаг также доступен для
    запроса через API узлов (`?abr=1`, `?asbr=1`). Те же флаги сообщаются в
    реальном времени [OSPF Watcher](../monitoring/ospf-watcher.md).

!!! tip "Опциональные данные TE (FRRouting)"
    Добавьте `show ip ospf database opaque-area` в тот же файл для данных о
    пропускной способности, TE-метрике и административной группе. Граф
    строится и по одним LSA 1/2/5. См.
    [Traffic Engineering](../analysis/traffic-engineering.md).

## OSPFv3

| Производитель | Команда | Stub-сеть | External (перераспределённая) |
| --- | --- | :---: | :---: |
| Arista | `show ipv6 ospf database detail` | ✅ | ✅ |
| IP Infusion OcNOS | `show ipv6 ospf database router`, `network`, `external`, `intra-prefix` | ✅ | ✅ |
| Fortinet FortiOS | `get router info6 ospf database router`, `network`, `external`, `intra-prefix` | ✅ | ✅ |
| MikroTik RouterOS | `/routing/ospf/lsa/print detail without-paging where instance=v3` | ✅ | ✅ |

!!! note
    Для OcNOS и FortiOS нужны формы по типам LSA: команда без типа `show ipv6 ospf database` / `get router info6 ospf database` выводит только индексную таблицу, а `intra-prefix` обязателен, потому что OSPFv3 передаёт префиксы только в этом LSA.

## IS-IS

| Производитель | Команда | Stub-сеть | External (перераспределённая) | Флаги узла (OL/ATT) |
| --- | --- | --- | --- | :---: |
| Cisco | `show isis database detail` | ✅ | Пока нет (нужен пример LSDB) | ✅ |
| Juniper | `show isis database extensive` | ✅ (нужен пример LSDB для подтверждения) | Пока нет (нужен пример LSDB) | ✅ (нужен пример LSDB для подтверждения) |
| Nokia | `show router isis database detail` | ✅ (нужен пример LSDB для подтверждения) | Пока нет (нужен пример LSDB) | ✅ (нужен пример LSDB для подтверждения) |
| Huawei | `display isis lsdb verbose` | ✅ (нужен пример LSDB для подтверждения) | Пока нет (нужен пример LSDB) | ✅ (нужен пример LSDB для подтверждения) |
| ZTE | `show isis database verbose` | ✅ (нужен пример LSDB для подтверждения) | Пока нет (нужен пример LSDB) | ✅ (нужен пример LSDB для подтверждения) |
| FRRouting | `show isis database detail` | ✅ | Пока нет (нужен пример LSDB) | ✅ |
| IP Infusion OcNOS | `show isis database verbose` | ✅ | ✅ | ✅ |
| Fortinet FortiOS | `get router info isis database detail` | ✅ | ✅ | ✅ (нужен пример LSDB для подтверждения) |
| MikroTik RouterOS | `/routing/isis/lsp/print detail without-paging` | ✅ | ✅ | |

!!! info "Флаги узла (overload / attached)"
    Overload (OL) и attached (ATT) считываются из столбца `ATT/P/OL`
    каждого LSP при загрузке текстового файла, а также сообщаются в
    реальном времени [IS-IS Watcher](../monitoring/isis-watcher.md)
    (который дополнительно вычисляет ABR/ASBR через BGP-LS).

!!! info "Столкнулись с неподдерживаемым случаем?"
    Несколько сценариев IS-IS отмечены как «нужен пример LSDB» - если
    вы можете поделиться примером базы данных, поддержку можно добавить.
    Откройте issue в соответствующем репозитории.

## Поддержка TLV IS-IS { #is-is-tlv-support }

Парсер IS-IS (используемый Topolograph и
[IS-IS Watcher](../monitoring/isis-watcher.md)) понимает следующие TLV:

| TLV | № | RFC | Cisco | Juniper | Nokia | FRR | Huawei | ZTE | MikroTik |
| --- | :-: | --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| IS Reachability | 2 | ISO 10589 | ✅ | ✅ | ✅ | ✅ |  | ✅ | ✅ |
| Extended IS Reachability (new) | 22 | RFC 5305 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv4 Internal Reachability (old) | 128 | RFC 1195 | ✅ | ✅ | ✅ | ✅ | ✅ |  | ✅ |
| IPv4 External Reachability (old) | 130 | RFC 1195 |  |  |  |  |  |  |  |
| Extended IPv4 Reachability (new) | 135 | RFC 5305 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv6 Reachability | 236 | RFC 5308 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Разбираются как **narrow** (метрики старого стиля), так и **wide** (метрики
нового стиля). Wide-метрики несут атрибуты TE - см.
[Traffic Engineering](../analysis/traffic-engineering.md).

## Атрибуты TE по производителям { #te-attributes-by-vendor }

Что разбирает парсер каждого производителя. Пустая ячейка означает, что атрибут не считывается из этого вывода, даже если маршрутизатор его анонсирует. Сессия [Watcher](../monitoring/isis-watcher.md) или BGP-LS передаёт все атрибуты, которые анонсирует маршрутизатор.

### IS-IS { #te-is-is }

| Атрибут TE | Имя в API/SDK | Определён в | FRR | Nokia | ZTE | OcNOS |
| --- | --- | --- | :-: | :-: | :-: | :-: |
| TE-метрика по умолчанию | `temetric` | RFC 5305 §3.7, sub-TLV 18 | ✅ | ✅ |  | ✅ |
| Административная группа | `admin_group` | RFC 5305 §3.1, sub-TLV 3 | ✅ | ✅ | ✅ |  |
| Максимальная пропускная способность линка | `max_link_bw` | RFC 5305 §3.4, sub-TLV 9 | ✅ | ✅ | ✅ |  |
| Максимальная резервируемая пропускная способность | `max_rsrv_link_bw` | RFC 5305 §3.5, sub-TLV 10 | ✅ | ✅ | ✅ |  |
| Нерезервированная пропускная способность (по приоритетам) | `unreserved_bw_0` … `unreserved_bw_7` | RFC 5305 §3.6, sub-TLV 11 | ✅ | ✅ | ✅ |  |
| Shared risk link group | `srlg` | RFC 5307 §1.2, TLV 138 | ✅ |  |  |  |
| Адрес интерфейса / соседа | `local_ip_address`, `remote_ip_address` | RFC 5305 §3.2, §3.3, sub-TLVs 6 / 8 | ✅ | ✅ | ✅ |  |
| Local / remote ID линка | `link_local_id`, `link_remote_id` | RFC 5307 §1.1, sub-TLV 4 |  |  | ✅ |  |

Команды, которые выводят sub-TLV: `show isis database detail` (FRR), `show router isis database detail` (Nokia SR OS), `show isis database verbose` (ZTE, IP Infusion OcNOS). OcNOS выводит sub-TLV TE только с `verbose`, но не с `detail`.

!!! note
    FRR выводит SRLG только в сборках, включающих [FRRouting/frr#22392](https://github.com/FRRouting/frr/pull/22392).

### OSPF { #te-ospf }

| Атрибут TE | Имя в API/SDK | Определён в | FRR | OcNOS |
| --- | --- | --- | :-: | :-: |
| TE-метрика по умолчанию | `temetric` | RFC 3630 §2.5.5, sub-TLV 5 | ✅ | ✅ |
| Административная группа | `admin_group` | RFC 3630 §2.5.9, sub-TLV 9 | ✅ |  |
| Максимальная пропускная способность линка | `max_link_bw` | RFC 3630 §2.5.6, sub-TLV 6 | ✅ |  |
| Максимальная резервируемая пропускная способность | `max_rsrv_link_bw` | RFC 3630 §2.5.7, sub-TLV 7 | ✅ |  |
| Нерезервированная пропускная способность (по приоритетам) | `unreserved_bw_0` … `unreserved_bw_7` | RFC 3630 §2.5.8, sub-TLV 8 | ✅ |  |
| Shared risk link group | `srlg` | RFC 4203 §1.3, sub-TLV 16 |  |  |
| Адрес локального / удалённого интерфейса | `local_ip_address`, `remote_ip_address` | RFC 3630 §2.5.3, §2.5.4, sub-TLVs 3 / 4 | ✅ | ✅ |

Добавьте `show ip ospf database opaque-area` в тот же файл загрузки. OcNOS выводит TE-метрику как `Admin Metric`.

## Поддерживаемые RFC { #supported-rfcs }

RFC, реализованные в парсерах и расчётах Topolograph.

| Протокол | RFC | Что считывает Topolograph |
| --- | --- | --- |
| OSPFv2 | RFC 2328 | LSA Router (1), Network (2) и AS-External (5) |
| OSPFv2 | RFC 3630 | Атрибуты TE линков из LSA opaque-area (тип 10) |
| OSPFv2 | RFC 4203 | Shared risk link group (SRLG), если значения приходят от Watcher |
| OSPFv2 | RFC 6987 | Флаг stub router (max-metric) на узлах |
| OSPFv3 | RFC 5340 | LSA Router, Network, AS-External и Intra-Area-Prefix |
| IS-IS | ISO/IEC 10589 | IS Reachability (TLV 2), базы Level 1 / Level 2, биты overload и attached |
| IS-IS | RFC 1195 | IPv4 Internal Reachability (TLV 128) |
| IS-IS | RFC 5305 | Extended IS и IPv4 Reachability (TLV 22, 135) и sub-TLV TE |
| IS-IS | RFC 5307 | Shared risk link group (TLV 138) и идентификаторы local / remote линка |
| IS-IS | RFC 5308 | IPv6 Reachability (TLV 236) |
| MPLS TE | RFC 3209 | Приоритеты setup и holding при CSPF-размещении LSP-туннелей |
| BGP | RFC 4271, RFC 4456, RFC 4364 | Выбор лучшего пути, route reflection и VPN-маршруты |
| BGP | RFC 7854, RFC 8671, RFC 9069 | BMP: Adj-RIB-In / Adj-RIB-Out и Loc-RIB |

## Передача данных через BGP-LS

Помимо текстовых файлов, топологию OSPF и IS-IS можно передавать в
реальном времени через **BGP-LS**, используя соответствующий Watcher. См.
[Сессия BGP-LS](../ingestion/bgp-ls.md).

---

Актуальная интерактивная схема API всегда доступна по адресу `/api/ui/` на
вашем экземпляре.

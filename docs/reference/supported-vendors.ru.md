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

## IS-IS

| Производитель | Команда | Stub-сеть | External (перераспределённая) | Флаги узла (OL/ATT) |
| --- | --- | --- | --- | :---: |
| Cisco | `show isis database detail` | ✅ | Пока нет (нужна проверенная LSDB) | ✅ |
| Juniper | `show isis database extensive` | ✅ (нужна проверенная LSDB для подтверждения) | Пока нет (нужна проверенная LSDB) | ✅ (нужна проверенная LSDB для подтверждения) |
| Nokia | `show router isis database detail` | ✅ (нужна проверенная LSDB для подтверждения) | Пока нет (нужна проверенная LSDB) | ✅ (нужна проверенная LSDB для подтверждения) |
| Huawei | `display isis lsdb verbose` | ✅ (нужна проверенная LSDB для подтверждения) | Пока нет (нужна проверенная LSDB) | ✅ (нужна проверенная LSDB для подтверждения) |
| ZTE | `show isis database verbose` | ✅ (нужна проверенная LSDB для подтверждения) | Пока нет (нужна проверенная LSDB) | ✅ (нужна проверенная LSDB для подтверждения) |

!!! info "Флаги узла (overload / attached)"
    Overload (OL) и attached (ATT) считываются из столбца `ATT/P/OL`
    каждого LSP при загрузке текстового файла, а также сообщаются в
    реальном времени [IS-IS Watcher](../monitoring/isis-watcher.md)
    (который дополнительно вычисляет ABR/ASBR через BGP-LS).

!!! info "Столкнулись с неподдерживаемым случаем?"
    Несколько сценариев IS-IS отмечены как «нужна проверенная LSDB» - если
    вы можете поделиться примером базы данных, поддержку можно добавить.
    Откройте issue в соответствующем репозитории.

## Поддержка TLV IS-IS { #is-is-tlv-support }

Парсер IS-IS (используемый Topolograph и
[IS-IS Watcher](../monitoring/isis-watcher.md)) понимает следующие TLV:

| TLV | № | Cisco | Juniper | Nokia | FRR | Huawei | ZTE |
| --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| IS Reachability | 2 | ✅ | ✅ | ✅ | ✅ | | ✅ |
| Extended IS Reachability (new) | 22 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv4 Internal Reachability (old) | 128 | ✅ | ✅ | ✅ | ✅ | ✅ | |
| IPv4 External Reachability (old) | 130 | | | | | | |
| Extended IPv4 Reachability (new) | 135 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| IPv6 Reachability | 236 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Разбираются как **narrow** (метрики старого стиля), так и **wide** (метрики
нового стиля). Wide-метрики несут атрибуты TE - см.
[Traffic Engineering](../analysis/traffic-engineering.md).

## Передача данных через BGP-LS

Помимо текстовых файлов, топологию OSPF и IS-IS можно передавать в
реальном времени через **BGP-LS**, используя соответствующий Watcher. См.
[Сессия BGP-LS](../ingestion/bgp-ls.md).

---

Актуальная интерактивная схема API всегда доступна по адресу `/api/ui/` на
вашем экземпляре.

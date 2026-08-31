# Загрузка текстового файла

Самый простой способ передать топологию в Topolograph: скопируйте LSDB с **одного** маршрутизатора и
вставьте (или загрузите) её. Никаких агентов, никаких туннелей, ничего, что
затрагивает действующую сеть.

![Загрузка текстового файла LSDB и построение кратчайших путей](../assets/text_file_and_short_paths.gif)

## Почему достаточно одного маршрутизатора

OSPF и IS-IS - это протоколы link-state: каждый маршрутизатор внутри
области/уровня хранит **идентичную** копию базы данных этой области.
Topolograph восстанавливает всю топологию по этой единственной копии - то
есть собрать её нужно всего один раз, с одного устройства.

Чтобы видеть сеть в нескольких area, соберите вывод с **ABR** (Area Border
Router): он хранит LSDB всех областей, к которым подключён.

## 1. Соберите базу данных

Выполните команды получения базы данных LSA/LSP для своей платформы и
сохраните вывод в обычный текстовый файл. Полная таблица приведена ниже; про
OSPFv3 и детали TLV IS-IS см. [Поддерживаемые производители](../reference/supported-vendors.md).

=== "OSPF (OSPFv2)"

    | Производитель | LSA 1 (router) | LSA 2 (network) | LSA 5 (external) |
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

    [^ubnt]: Применимо к линейке EdgeRouter и более старым шлюзам UniFi USG.
        Новые шлюзы UniFi используют проект [FRRouting](https://frrouting.org).

=== "OSPFv3"

    | Производитель | Команда |
    | --- | --- |
    | Arista | `show ipv6 ospf database detail` |

=== "IS-IS"

    | Производитель | Команда получения базы данных |
    | --- | --- |
    | Cisco | `show isis database detail` |
    | Juniper | `show isis database extensive` |
    | Nokia | `show router isis database detail` |
    | Huawei | `display isis lsdb verbose` |
    | ZTE | `show isis database verbose` |

Секции LSA 1 / 2 / 5 (OSPF) можно поместить в один файл - Topolograph
разбирает их вместе.

!!! tip "Опционально: более подробные линки с данными TE"
    Для FRRouting OSPF добавьте в тот же файл вывод команды
    `show ip ospf database opaque-area`, чтобы включить пропускную
    способность линка, TE-метрику и административную группу. Граф строится и
    без этого. См. [Traffic Engineering](../analysis/traffic-engineering.md).

## 2. Загрузите его

1. Откройте Topolograph (`http://localhost:8080/` для
   [локальной установки](../getting-started/quickstart-docker.md)).
2. Начните загрузку топологии и вставьте или прикрепите свой текстовый файл.
3. Выберите подходящие **производителя** и **протокол** (OSPF / IS-IS).
4. При желании задайте **имя** загрузки (например, `до обновления
   маршрутизатора` или `до работ на сети`), чтобы потом найти этот снимок.
5. Нажмите кнопку **Upload hosts**. Topolograph разберёт базу данных и
   отобразит граф.

![Загрузка текстового файла LSDB и построение кратчайших путей](../assets/text_file_and_short_paths.gif)

Результат - это **снимок**: замороженная картина сети на момент загрузки в
Topolograph.
Весь анализ выполняется на этом снимке, поэтому ничто из ваших действий не
затрагивает реальную сеть.

## 3. Сравнивайте состояния во времени

Загрузите обновлённый файл LSDB позже, и Topolograph сможет **сравнить** два
снимка, точно показав, что изменилось - новые/удалённые узлы и линки,
изменения метрик, появившиеся и исчезнувшие сети. См.
[Сравнение состояний сети](../analysis/comparing-states.md).

## Загрузка через API

Всё, что можно вставить, можно и отправить через `POST`.
[Python SDK](../automation/python-sdk.md) оборачивает этот вызов - и может
даже собрать LSDB с ваших устройств по SSH и загрузить её за один шаг:

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

**Хотите обновления в реальном времени вместо снимков?** Передавайте
топологию через сессию Watcher по [GRE](gre.md) или [BGP-LS](bgp-ls.md).

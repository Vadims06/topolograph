# Traffic Engineering (TE)

Помимо базовой метрики IGP, OSPF и IS-IS могут нести атрибуты **Traffic
Engineering** - пропускную способность, отдельную TE-метрику и
административные группы/affinity. Topolograph разбирает их и делает
доступными для более детальной визуализации и фильтрации - как для
**OSPF**, так и для **IS-IS**.

!!! info "TE опционален"
    Ваш граф прекрасно строится из обычных LSA 1/2/5 (OSPF) или стандартной
    LSDB IS-IS. Данные TE - это *дополнение*, включайте их, когда нужен
    анализ с учётом пропускной способности.

## Что разбирает Topolograph { #what-topolograph-parses }

| Атрибут | Имя в API/SDK | Значение | Определён в |
| --- | --- | --- | --- |
| TE-метрика по умолчанию | `temetric` | Метрика линка, специфичная для TE (не зависит от метрики IGP) | RFC 3630 §2.5.5 / RFC 5305 §3.7 |
| Административная группа | `admin_group` | Affinity / цвет / класс ресурса | RFC 3630 §2.5.9 / RFC 5305 §3.1 |
| Максимальная пропускная способность линка | `max_link_bw` | Физическая пропускная способность линка | RFC 3630 §2.5.6 / RFC 5305 §3.4 |
| Максимальная резервируемая пропускная способность | `max_rsrv_link_bw` | Пропускная способность, доступная для резервирования | RFC 3630 §2.5.7 / RFC 5305 §3.5 |
| Нерезервированная пропускная способность (по приоритетам) | `unreserved_bw_0` … `unreserved_bw_7` | Оставшаяся пропускная способность на каждом из 8 приоритетов TE | RFC 3630 §2.5.8 / RFC 5305 §3.6 |
| Shared risk link group | `srlg` | Список идентификаторов SRLG, к которым принадлежит линк (RFC 4203 / RFC 5307) | RFC 4203 §1.3 / RFC 5307 §1.2 |

**Одни и те же имена атрибутов** используются независимо от того, пришли
данные из OSPF или из IS-IS.

## Как передать данные TE

=== "OSPF - текстовый файл"

    Включите **`show ip ospf database opaque-area`** в тот же файл загрузки,
    что и LSDB router/network/external. LSA типа 10 (opaque-area) несут
    данные TE; остальная часть графа строится из LSA 1, 2 и 5 как обычно.
    Поддерживаются FRRouting и IP Infusion OcNOS.

    [:octicons-arrow-right-24: Загрузка текстового файла](../ingestion/text-file.md)

=== "IS-IS - текстовый файл"

    Атрибуты TE поступают напрямую из LSDB IS-IS, если вы используете подробную команду производителя: **`show isis database detail`** (FRR), **`show router isis database detail`** (Nokia SR OS) или **`show isis database verbose`** (ZTE, IP Infusion OcNOS). Никакой дополнительной команды сверх обычного захвата IS-IS не требуется. Какие атрибуты разбирает парсер каждого производителя, указано в разделе [Атрибуты TE по производителям](../reference/supported-vendors.md#te-attributes-by-vendor).

=== "OSPF / IS-IS - BGP-LS"

    **BGP-LS нативно передаёт атрибуты TE** - административную группу,
    максимальную и резервируемую пропускную способность, нерезервированную
    пропускную способность, SRLG и TE-метрику по умолчанию - без трюка с
    opaque-LSA. Обновления TE поступают на страницу мониторинга в реальном
    времени.

    [:octicons-arrow-right-24: Сессия BGP-LS](../ingestion/bgp-ls.md)

Когда данные TE поступают через BGP-LS, страница мониторинга показывает
атрибуты линка по мере поступления обновлений:

![Атрибуты TE линка на странице мониторинга через BGP-LS](../static/te_link_attributes_on_monitoring_page_full_with_bgpls_1.png)

## Фильтрация линков по атрибутам TE

Как только диаграмма содержит данные TE, вы можете запрашивать линки по
любому атрибуту TE с помощью операторов диапазона `__gt`, `__lt`, `__gte`,
`__lte` - удобно для поиска линков, которые удовлетворяют или не
удовлетворяют условию TE. С помощью [Python SDK](../automation/python-sdk.md):

```python
# Links with TE metric >= 100
edges = graph.edges_list(temetric__gte=100)

# Links with unreserved bandwidth at priority 0 below 1 Gbps
edges = graph.edges_list(unreserved_bw_0__lt=1e9)

# Links between two nodes with max link bandwidth above 10 Gbps
edges = graph.edges_list(src_node="1.1.1.1", dst_node="2.2.2.2", max_link_bw__gt=1e10)
```

Такая же фильтрация доступна через REST API линков диаграммы.

## Особенности IS-IS

TE в IS-IS опирается на **Wide Metrics** (Extended IS/IP Reachability,
TLV 22/135) и поддерживает достижимость **IPv6** (TLV 236). Поддержка
соответствующих TLV по производителям приведена на странице
[Поддерживаемые производители](../reference/supported-vendors.md#is-is-tlv-support).

Атрибуты TE, которые считываются у каждого производителя, перечислены в разделе [Атрибуты TE по производителям](../reference/supported-vendors.md#te-attributes-by-vendor).

## Мониторинг изменений TE

Когда подключён Watcher, изменения атрибутов TE фиксируются как события
наряду с изменениями метрики и соседства - см. представления `te_log` в
разделах [ELK / Kibana](../monitoring/elk-kibana.md) и
[IS-IS Watcher](../monitoring/isis-watcher.md).

---

**Связанные страницы:** [Получение топологии](../ingestion/index.md) ·
[Визуализация и анализ](visualizing.md)

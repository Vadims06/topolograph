# IS-IS Watcher

**IS-IS Watcher** - аналог [OSPF Watcher](ospf-watcher.md) для IS-IS. Он
пассивно слушает control plane IS-IS - через [соседство по GRE](../ingestion/gre.md)
или [BGP-LS](../ingestion/bgp-ls.md) - и логирует или экспортирует каждое
изменение в **ELK**, **Zabbix**, **WebHooks** и на дашборд мониторинга
**Topolograph**. Как и OSPF Watcher, он поставляется в виде контейнеров.

[:simple-github: vadims06/isiswatcher](https://github.com/Vadims06/isiswatcher){ .md-button }

![Архитектура IS-IS Watcher + Topolograph](../assets/isiswatcher_architecture.png)

## Обнаруживаемые события

- **Подъём/разрыв** соседства с IS-IS-соседом
- **Изменения метрики** линка IS-IS
- **Появление/исчезновение** сетей IS-IS
- **Атрибуты TE** IS-IS: административная группа, максимальная пропускная
  способность линка, максимальная резервируемая пропускная способность,
  нерезервированная пропускная способность, TE-метрика по умолчанию и
  shared risk link group (SRLG)
- **Флаги узла** IS-IS: переходы **overload (OL)** и **attached (ATT)**
  (плюс ABR/ASBR, вычисляемые через BGP-LS)

Всё группируется по **уровню IS-IS (L1/L2)** на временной шкале:

![Дашборд Topolograph с событиями IS-IS L1/L2](../assets/dashboard_l1_l2_events.png)

!!! example "Как выглядят уровни"
    Типичный захват может показывать: изменение метрики линка,
    отображающееся как **дублированные записи для L1 и L2**;
    маршрутизатор, переходящий **в состояние down только для L2** после
    применения `isis circuit-type level-1`; более позднее изменение
    метрики, видимое **только в L1**; и новую stub-сеть, появляющуюся **в
    L2**.

## Подключение

Настройка подключения описана в разделе [Получение топологии](../ingestion/index.md):

- [**Режим GRE**](../ingestion/gre.md) - FRR устанавливает соседство IS-IS
  через туннель GRE; **XDP-фильтр IS-IS** сохраняет Watcher только
  слушателем, отбрасывая любой LSP, который анонсирует больше, чем
  собственная сеть Watcher-а.
- [**Режим BGP-LS**](../ingestion/bgp-ls.md) - маршрутизатор экспортирует
  топологию IS-IS через BGP-LS; GoBGP + BGP-LS Watcher передают данные
  Watcher-у.

![Отдельные экземпляры GRE FRR на каждую область](../assets/gre_frr_instances.png)

!!! warning "Один туннель GRE на каждую область"
    IS-IS, как и OSPF, распространяет данные по областям/уровням отдельно.
    В режиме GRE вам нужен **как минимум один туннель GRE в каждую
    область**, которую вы хотите мониторить - это свойство распространения
    данных link-state, а не ограничение инструмента. BGP-LS избегает этого,
    передавая весь домен через одну сессию.

!!! note "Совместимость"
    Изменения сетей IS-IS отображаются на графе начиная с
    [topolograph v2.38](https://github.com/Vadims06/topolograph/releases/tag/v2.38)
    и новее.

## Поддержка TLV и метрик

IS-IS Watcher разбирает как метрики старого стиля (narrow), так и нового
стиля (wide), и поддерживает достижимость IPv6. Понимаемые им TLV - и
таблица поддержки по производителям - приведены на странице
[Поддерживаемые производители](../reference/supported-vendors.md#is-is-tlv-support).

Ключевые TLV: IS Reachability (2), Extended IS Reachability (22), IPv4
Internal/Extended Reachability (128/135) и IPv6 Reachability (236).

!!! info "Специальная сборка FRR"
    Для запуска IS-IS через GRE нужна сборка FRR, которая это поддерживает;
    репозиторий IS-IS Watcher предоставляет необходимую сборку. Подробности
    в [репозитории](https://github.com/Vadims06/isiswatcher).

## Быстрая лаборатория (containerlab)

В репозитории есть топология containerlab для сквозного опробования
мониторинга IS-IS - см. каталог `containerlab/` и таблицу
[размеров развёртывания](index.md#deployment-sizes) о том, как добавить
Topolograph и ELK.

!!! tip "Нет устройства? Тестовый режим"
    Как и в OSPF Watcher, `TEST_MODE` воспроизводит демонстрационные события
    IS-IS из статического файла, чтобы вы могли опробовать весь конвейер
    без оборудования.

## Формат журнала событий

IS-IS Watcher генерирует те же записи событий, разделённые запятыми, что и
OSPF Watcher (с добавлением **уровня** IS-IS) - поэтому интеграции с
[ELK](elk-kibana.md), [Zabbix](zabbix.md) и [Webhook](webhooks.md) работают
точно так же. Разбор по полям - в разделе
[формата журнала OSPF Watcher](ospf-watcher.md#event-log-format).

---

**Связанные страницы:** [OSPF Watcher](ospf-watcher.md) ·
[Traffic Engineering](../analysis/traffic-engineering.md) ·
[ELK / Kibana](elk-kibana.md)

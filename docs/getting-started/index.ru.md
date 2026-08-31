# Начало работы

Начните здесь знакомство с Topolograph.

<div class="grid cards" markdown>

-   :material-help-circle-outline:{ .lg .middle } __Что такое Topolograph?__

    ---

    Узнайте, что делает Topolograph, какую проблему решает и как части набора
    инструментов работают вместе.

    [:octicons-arrow-right-24: Читать обзор](what-is-topolograph.md)

-   :material-docker:{ .lg .middle } __Быстрый старт с Docker__

    ---

    Разверните локальный экземпляр за несколько минут с помощью Docker Compose.

    [:octicons-arrow-right-24: Установка через Docker](quickstart-docker.md)

-   :material-rocket-launch-outline:{ .lg .middle } __Воспользуйтесь демо-топологией__

    ---

    Демо-топология из 13 маршрутизаторов загружается автоматически при первом
    запуске и доступна всем пользователям - можно сразу строить пути, ничего
    не загружая.

    [:octicons-arrow-right-24: Анализ и визуализация](../analysis/index.md)

-   :material-flag-checkered:{ .lg .middle } __Ваша первая топология__

    ---

    Загрузите вывод LSDB с одного маршрутизатора и постройте свой первый путь.

    [:octicons-arrow-right-24: Постройте свой первый граф](first-topology.md)

</div>

## С чего начать

1. **Запустите Topolograph** локально с помощью [Docker](quickstart-docker.md).
2. **Перейдите во вкладку «Загрузить топологию»** и начните работать с уже
   предустановленным демо-графом.
3. **Проанализируйте демо-граф** - [стройте пути, моделируйте отказы,
   находите слабые места](../analysis/index.md).

## Дальнейшие шаги

1. **Загрузите свою топологию** - [вставьте текстовый файл LSDB](../ingestion/text-file.md)
   или получайте её в реальном времени через сессию Watcher по [GRE](../ingestion/gre.md)
   или [BGP-LS](../ingestion/bgp-ls.md).
2. **Включите мониторинг** - запустите [Watcher](../monitoring/index.md), чтобы
   фиксировать каждое изменение и получать оповещения.

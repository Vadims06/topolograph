# Развёртывание и настройка

Эта страница собирает параметры развёртывания для self-hosted Topolograph.
Пошаговый первый запуск описан в разделе
[Быстрый старт с Docker](../getting-started/quickstart-docker.md).

## Установка

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
# or: sudo ./install.sh   (can also bring up the Watchers)
```

Откройте `http://localhost:8080/`.

## Переменные окружения

Конфигурация хранится в `.env` рядом с `docker-compose.yml`.

| Переменная | Назначение |
| --- | --- |
| `TOPOLOGRAPH_PORT` | Порт веб-интерфейса (по умолчанию `8080`). |
| `MCP_PORT` | Порт [MCP-сервера](../automation/mcp-server.md) (по умолчанию `8000`). |
| `DNS` | IP DNS-сервера, используемого для преобразования router ID в имена устройств. |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL`, `TOPOLOGRAPH_WEB_API_PASSWORD` | Учётные данные REST API. |
| `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS` | Список разрешённых диапазонов исходных IP для вызовов API. |
| `TOPOLOGRAPH_API_TOKEN` | Токен для аутентификации запросов к REST API вместо пары логин/пароль. |

После изменения любого значения примените его заново командой
`docker-compose up -d`.

### Переменные на стороне Watcher-а

Когда вы также запускаете [Watcher](../monitoring/index.md), в его `.env`
добавляется ещё несколько переменных:

| Переменная | Назначение |
| --- | --- |
| `TOPOLOGRAPH_HOST` | IP хоста, на котором работает Topolograph. **Не используйте `localhost`** - Watcher, ELK и Topolograph работают в собственных сетевых пространствах. |
| `TOPOLOGRAPH_PORT` | Порт Topolograph (по умолчанию `8080`). |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `_PASSWORD` | Пользователь API, от имени которого Watcher отправляет данные (например, `ospf@topolograph.com`). |
| `TEST_MODE` | При `True` воспроизводит демонстрационные события из статического файла вместо чтения живого IGP. |
| `WATCHER_IP` | Переопределяет сообщаемый исходный IP Watcher-а (`srcid`), когда разрешение имени хоста в контейнерах ненадёжно. |
| `EXPORT_TO_ELASTICSEARCH_BOOL`, `ELASTIC_IP` | Включает и указывает адрес стека [ELK](../monitoring/elk-kibana.md). |
| `EXPORT_TO_WEBHOOK_URL_BOOL`, `WEBHOOK_URL` | Включает уведомления [WebHook/Slack](../monitoring/webhooks.md). |

## Создание учётных данных по умолчанию

Выполните один раз, чтобы создать пользователя API из вашего `.env` и
загрузить разрешённые сети:

```python
import requests
print(requests.post('http://localhost:8080/create-default-credentials').json())
# {'errors': '', 'status': 'ok'}
```

Проверка: войдите на `http://localhost:8080/` через **Login → Local
login**, затем проверьте вкладку **API → Authorised source IP ranges**.

## Что входит в стек

Compose-файл `topolograph-docker` может запускать, в любой комбинации:

- **Topolograph** - веб-приложение + база данных
- **MCP-сервер** (`/mcp` на `MCP_PORT`)
- **OSPF / IS-IS Watcher-ы**
- Стек **ELK** для поиска по событиям

## Облачная альтернатива

Облачный экземпляр доступен на [topolograph.com](https://topolograph.com).
Выбирайте self-hosting, когда ваши данные LSDB должны оставаться внутри
вашей инфраструктуры.

---

**Связанные страницы:** [Быстрый старт](../getting-started/quickstart-docker.md) ·
[Мониторинг в реальном времени](../monitoring/index.md)

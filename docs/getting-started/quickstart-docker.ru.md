# Быстрый старт с Docker

Самый быстрый способ запустить Topolograph - использовать self-hosted образ
Docker. В нём собраны веб-приложение, база данных и (опционально) MCP-сервер
и Watcher-ы.

!!! tip "Предварительные требования"
    Установите **Docker** и **Docker Compose**. В Windows/macOS Docker Desktop
    включает и то, и другое.

## 1. Клонируйте и запустите

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
```

Используйте скрипт `install.sh`:

```bash
sudo ./install.sh
```

…или запустите его прямо из GitHub:

```bash
curl -O https://raw.githubusercontent.com/Vadims06/topolograph-docker/master/install.sh
chmod +x install.sh
sudo ./install.sh
```

Дайте ему минуту-другую на запуск, затем откройте:

```
http://localhost:8080/
```

## 2. Настройка через `.env`

Конфигурация хранится в файле `.env` рядом с `docker-compose.yml`. Самые
полезные переменные:

| Переменная | Назначение |
| --- | --- |
| `TOPOLOGRAPH_PORT` | Порт веб-интерфейса (по умолчанию `8080`). После перезапуска откройте `http://localhost:<port>/`. |
| `DNS` | IP DNS-сервера, используемого для преобразования router ID в имена устройств на графе. |
| `DNS_LOOKUP_DEADLINE_SEC` | Максимальное время в секундах, которое загрузка ждёт ответа DNS (по умолчанию `5`). Узлы, не разрешённые вовремя, остаются подписаны IP-адресом. |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL`, `TOPOLOGRAPH_WEB_API_PASSWORD` | Учётные данные для запросов к REST API. |
| `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS` | Список разрешённых диапазонов исходных IP-адресов, которым можно обращаться к API. |
| `TOPOLOGRAPH_API_TOKEN` | Токен для аутентификации запросов к REST API вместо пары логин/пароль. |
| `MCP_PORT` | Порт для встроенного [MCP-сервера](../automation/mcp-server.md) (по умолчанию `8000`). |

После изменения порта или другого значения примените его заново:

```bash
docker-compose up -d
```

## 3. Создайте учётные данные по умолчанию

Чтобы создать пользователя API из значений вашего `.env` и загрузить
разрешённые сети в список доступа, один раз отправьте этот запрос:

```python
import requests
res = requests.post('http://localhost:8080/create-default-credentials')
print(res.json())
# {'errors': '', 'status': 'ok'}
```

Проверьте, что всё сработало:

1. Откройте `http://localhost:8080/` в браузере.
2. Перейдите в **Login → Local login** и войдите с помощью
   `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `TOPOLOGRAPH_WEB_API_PASSWORD`.
3. На вкладке **API → Authorised source IP ranges** должны отображаться
   диапазоны из `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS`.

## Что входит в комплект

`docker-compose.yml` в `topolograph-docker` может запускать не только
веб-приложение:

- **Topolograph** - веб-приложение + база данных.
- **MCP-сервер** по адресу `http://localhost:8000/mcp` для
  [доступа LLM/агентов](../automation/mcp-server.md).
- Опционально - **OSPF/IS-IS Watcher-ы** и стек **ELK** для
  [мониторинга в реальном времени](../monitoring/index.md).

!!! note "Облачный вариант"
    Не хотите разворачивать самостоятельно? Облачный экземпляр доступен на
    [topolograph.com](https://topolograph.com). Версия для Docker идеальна,
    когда ваши LSDB не должны покидать вашу инфраструктуру.

---

**Далее:** [Постройте свою первую топологию →](first-topology.md)

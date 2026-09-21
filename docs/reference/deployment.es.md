# Implementación y configuración

Esta página reúne los parámetros de implementación de un Topolograph
autoalojado. Para una primera ejecución paso a paso, consulte el
[Inicio Rápido con Docker](../getting-started/quickstart-docker.md).

## Instalación

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d

!!! info "Sin analítica de terceros"
    La imagen Docker no carga los contadores de Google Analytics y Yandex Metrika que usa topolograph.com.
# o: sudo ./install.sh   (también puede levantar los Watchers)
```

Abra `http://localhost:8080/`.

## Variables de entorno

La configuración vive en `.env`, junto a `docker-compose.yml`.

| Variable | Propósito |
| --- | --- |
| `TOPOLOGRAPH_PORT` | Puerto de la interfaz web (por defecto `8080`). |
| `MCP_PORT` | Puerto del [servidor MCP](../automation/mcp-server.md) (por defecto `8000`). |
| `DNS` | IP del servidor DNS usado para resolver router IDs a nombres de dispositivo. |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL`, `TOPOLOGRAPH_WEB_API_PASSWORD` | Credenciales de la API REST. |
| `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS` | Lista de permitidos de rangos de IP de origen para llamadas a la API. |
| `TOPOLOGRAPH_API_TOKEN` | Token para autenticar solicitudes a la API REST en lugar de un par usuario/contraseña. |

Después de cambiar cualquier valor, vuelva a aplicar con `docker-compose up -d`.

### Variables del lado del Watcher

Cuando también ejecuta un [Watcher](../monitoring/index.md), su `.env`
añade algunas más:

| Variable | Propósito |
| --- | --- |
| `TOPOLOGRAPH_HOST` | IP del host que ejecuta Topolograph. **No use `localhost`** — el Watcher, ELK y Topolograph se ejecutan cada uno en su propio espacio de red. |
| `TOPOLOGRAPH_PORT` | Puerto de Topolograph (por defecto `8080`). |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `_PASSWORD` | Usuario de API con el que el Watcher publica (p. ej. `ospf@topolograph.com`). |
| `TEST_MODE` | Si es `True`, reproduce eventos de demostración desde un archivo estático en lugar de leer el IGP en vivo. |
| `WATCHER_IP` | Sobrescribe la IP de origen reportada por el Watcher (`srcid`) cuando la resolución de hostname no es fiable en contenedores. |
| `EXPORT_TO_ELASTICSEARCH_BOOL`, `ELASTIC_IP` | Habilita y apunta a una pila [ELK](../monitoring/elk-kibana.md). |
| `EXPORT_TO_WEBHOOK_URL_BOOL`, `WEBHOOK_URL` | Habilita notificaciones vía [WebHook/Slack](../monitoring/webhooks.md). |

## Crear credenciales por defecto

Ejecute una vez para crear el usuario de API a partir de su `.env` y cargar
las redes permitidas:

```python
import requests
print(requests.post('http://localhost:8080/create-default-credentials').json())
# {'errors': '', 'status': 'ok'}
```

Verifique: inicie sesión en `http://localhost:8080/` vía **Login → Local
login**, luego revise **API → Authorised source IP ranges**.

## Qué incluye la pila

El compose de `topolograph-docker` puede ejecutar, en cualquier
combinación:

- **Topolograph** — aplicación web + base de datos
- **Servidor MCP** (`/mcp` en `MCP_PORT`)
- **Watchers de OSPF / IS-IS**
- Pila **ELK** para búsqueda de eventos

## Alternativa alojada

Hay una instancia alojada disponible en [topolograph.com](https://topolograph.com).
Elija el autoalojamiento cuando sus datos de LSDB deban permanecer dentro
de su entorno.

---

**Relacionado:** [Inicio Rápido](../getting-started/quickstart-docker.md) ·
[Monitoreo en tiempo real](../monitoring/index.md)

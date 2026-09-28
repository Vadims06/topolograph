# Inicio Rápido con Docker

La forma más rápida de ejecutar Topolograph es la imagen Docker autoalojada.
Incluye la aplicación web, su base de datos y (opcionalmente) el servidor
MCP y los Watchers.

!!! tip "Requisitos previos"
    Instale **Docker** y **Docker Compose**. En Windows/macOS, Docker Desktop
    incluye ambos.

## 1. Clonar e iniciar

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
```

¿Prefiere un instalador de un solo paso que también pueda levantar los
Watchers? Use el script `install.sh` en su lugar:

```bash
sudo ./install.sh
```

…o ejecútelo directamente desde GitHub:

```bash
curl -O https://raw.githubusercontent.com/Vadims06/topolograph-docker/master/install.sh
chmod +x install.sh
sudo ./install.sh
```

Dele un minuto o dos para que arranque, luego abra:

```
http://localhost:8080/
```

## 2. Configurar con `.env`

La configuración vive en un archivo `.env` junto a `docker-compose.yml`. Las
variables más útiles:

| Variable | Propósito |
| --- | --- |
| `TOPOLOGRAPH_PORT` | Puerto de la interfaz web (por defecto `8080`). Abra `http://localhost:<port>/` después de reiniciar. |
| `DNS` | IP de un servidor DNS, usada para resolver los router ID en nombres de dispositivo en el grafo. |
| `DNS_LOOKUP_DEADLINE_SEC` | Segundos máximos que una carga espera los nombres DNS (por defecto `5`). Los nodos no resueltos a tiempo conservan su IP como etiqueta. |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL`, `TOPOLOGRAPH_WEB_API_PASSWORD` | Credenciales para las solicitudes a la API REST. |
| `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS` | Lista de permitidos de rangos de IP de origen autorizados a llamar a la API. |
| `TOPOLOGRAPH_API_TOKEN` | Token para autenticar solicitudes a la API REST en lugar de un par usuario/contraseña. |
| `MCP_PORT` | Puerto del [servidor MCP](../automation/mcp-server.md) incluido (por defecto `8000`). |

Después de cambiar un puerto u otro valor, vuelva a aplicarlo:

```bash
docker-compose up -d
```

## 3. Crear las credenciales por defecto

Para crear el usuario de la API a partir de sus valores de `.env` y cargar
sus redes permitidas en la lista de permitidos, envíe esta solicitud una vez:

```python
import requests
res = requests.post('http://localhost:8080/create-default-credentials')
print(res.json())
# {'errors': '', 'status': 'ok'}
```

Verifique que funcionó:

1. Abra `http://localhost:8080/` en un navegador.
2. Vaya a **Login → Local login** e inicie sesión con
   `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `TOPOLOGRAPH_WEB_API_PASSWORD`.
3. La pestaña **API → Authorised source IP ranges** debería listar los rangos
   de `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS`.

## Qué incluye

El `docker-compose.yml` de `topolograph-docker` puede ejecutar más que solo
la aplicación web:

- **Topolograph** aplicación web + base de datos.
- **Servidor MCP** en `http://localhost:8000/mcp` para
  [acceso de LLM/agentes](../automation/mcp-server.md).
- **OSPF/IS-IS Watchers** opcionales y una pila **ELK** para
  [monitoreo en tiempo real](../monitoring/index.md).

!!! note "Opción alojada"
    ¿No quiere autoalojar? Hay una instancia alojada disponible en
    [topolograph.com](https://topolograph.com). La versión Docker es ideal
    cuando sus LSDB no deben salir de su entorno.

---

**Siguiente:** [Construya su primera topología →](first-topology.md)

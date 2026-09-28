# Implantação e configuração

Esta página reúne os parâmetros de implantação de um Topolograph
auto-hospedado. Para uma primeira execução passo a passo, veja o
[Início Rápido com Docker](../getting-started/quickstart-docker.md).

## Instalar

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d

!!! info "Sem análise de terceiros"
    A imagem Docker não carrega os contadores do Google Analytics e do Yandex Metrika que o topolograph.com usa.
# ou: sudo ./install.sh   (também pode subir os Watchers)
```

Abra `http://localhost:8080/`.

## Variáveis de ambiente

A configuração fica em `.env`, ao lado de `docker-compose.yml`.

| Variável | Finalidade |
| --- | --- |
| `TOPOLOGRAPH_PORT` | Porta da interface web (padrão `8080`). |
| `MCP_PORT` | Porta do [servidor MCP](../automation/mcp-server.md) (padrão `8000`). |
| `DNS` | IP do servidor DNS usado para resolver router IDs em nomes de dispositivo. |
| `DNS_LOOKUP_DEADLINE_SEC` | Tempo máximo em segundos que um upload aguarda os nomes DNS (padrão `5`). Nós não resolvidos a tempo mantêm o IP como rótulo. |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL`, `TOPOLOGRAPH_WEB_API_PASSWORD` | Credenciais da API REST. |
| `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS` | Lista de permissão de faixas de IP de origem para chamadas de API. |
| `TOPOLOGRAPH_API_TOKEN` | Token para autenticar requisições da API REST em vez de um par usuário/senha. |

Depois de alterar qualquer valor, reaplique com `docker-compose up -d`.

### Variáveis do lado do Watcher

Quando você também executa um [Watcher](../monitoring/index.md), o `.env`
dele adiciona mais algumas:

| Variável | Finalidade |
| --- | --- |
| `TOPOLOGRAPH_HOST` | IP do host que executa o Topolograph. **Não use `localhost`** — o Watcher, o ELK e o Topolograph rodam cada um em seu próprio espaço de rede. |
| `TOPOLOGRAPH_PORT` | Porta do Topolograph (padrão `8080`). |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `_PASSWORD` | Usuário de API com o qual o Watcher publica (ex.: `ospf@topolograph.com`). |
| `TEST_MODE` | Se `True`, reproduz eventos de demonstração de um arquivo estático em vez de ler o IGP ao vivo. |
| `WATCHER_IP` | Sobrescreve o IP de origem reportado pelo Watcher quando a resolução de hostname não é confiável em containers. |
| `EXPORT_TO_ELASTICSEARCH_BOOL`, `ELASTIC_IP` | Habilita e direciona para uma pilha [ELK](../monitoring/elk-kibana.md). |
| `EXPORT_TO_WEBHOOK_URL_BOOL`, `WEBHOOK_URL` | Habilita notificações via [WebHook/Slack](../monitoring/webhooks.md). |

## Criar credenciais padrão

Execute uma vez para criar o usuário de API a partir do seu `.env` e
carregar as redes permitidas:

```python
import requests
print(requests.post('http://localhost:8080/create-default-credentials').json())
# {'errors': '', 'status': 'ok'}
```

Verifique: faça login em `http://localhost:8080/` via **Login → Local
login**, depois confira **API → Authorised source IP ranges**.

## O que está na stack

O compose do `topolograph-docker` pode rodar, em qualquer combinação:

- **Topolograph** — aplicação web + banco de dados
- **Servidor MCP** (`/mcp` na `MCP_PORT`)
- **Watchers OSPF / IS-IS**
- Pilha **ELK** para busca de eventos

## Alternativa hospedada

Uma instância hospedada está disponível em [topolograph.com](https://topolograph.com).
Escolha a auto-hospedagem quando seus dados de LSDB precisarem permanecer
dentro do seu ambiente.

---

**Relacionado:** [Início Rápido](../getting-started/quickstart-docker.md) ·
[Monitoramento em tempo real](../monitoring/index.md)

# Início Rápido com Docker

A forma mais rápida de executar o Topolograph é a imagem Docker auto-hospedada.
Ela empacota o aplicativo web, seu banco de dados e, opcionalmente, o servidor
MCP e os Watchers.

!!! tip "Pré-requisitos"
    Instale o **Docker** e o **Docker Compose**. No Windows/macOS, o Docker
    Desktop inclui ambos.

## 1. Clone e inicie

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
```

Prefere um instalador de um único passo que também suba os Watchers? Use o
script `install.sh`:

```bash
sudo ./install.sh
```

…ou execute-o diretamente do GitHub:

```bash
curl -O https://raw.githubusercontent.com/Vadims06/topolograph-docker/master/install.sh
chmod +x install.sh
sudo ./install.sh
```

Dê um ou dois minutos para ele subir e depois abra:

```
http://localhost:8080/
```

## 2. Configure com `.env`

A configuração fica em um arquivo `.env` ao lado do `docker-compose.yml`. As
variáveis mais úteis:

| Variável | Finalidade |
| --- | --- |
| `TOPOLOGRAPH_PORT` | Porta da interface web (padrão `8080`). Abra `http://localhost:<port>/` após reiniciar. |
| `DNS` | IP de um servidor DNS, usado para resolver router IDs em nomes de dispositivos no grafo. |
| `DNS_LOOKUP_DEADLINE_SEC` | Tempo máximo em segundos que um upload aguarda os nomes DNS (padrão `5`). Nós não resolvidos a tempo mantêm o IP como rótulo. |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL`, `TOPOLOGRAPH_WEB_API_PASSWORD` | Credenciais para requisições à API REST. |
| `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS` | Lista de permissão de intervalos de IP de origem autorizados a chamar a API. |
| `TOPOLOGRAPH_API_TOKEN` | Token para autenticar requisições da API REST em vez de um par usuário/senha. |
| `MCP_PORT` | Porta do [servidor MCP](../automation/mcp-server.md) empacotado (padrão `8000`). |

Depois de alterar uma porta ou outro valor, reaplique-o:

```bash
docker-compose up -d
```

## 3. Crie as credenciais padrão

Para criar o usuário da API a partir dos seus valores em `.env` e carregar
suas redes permitidas na lista de permissão, envie esta requisição uma vez:

```python
import requests
res = requests.post('http://localhost:8080/create-default-credentials')
print(res.json())
# {'errors': '', 'status': 'ok'}
```

Verifique se funcionou:

1. Abra `http://localhost:8080/` em um navegador.
2. Vá em **Login → Local login** e entre com
   `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `TOPOLOGRAPH_WEB_API_PASSWORD`.
3. A aba **API → Authorised source IP ranges** deve listar os intervalos de
   `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS`.

## O que está incluído

O `docker-compose.yml` em `topolograph-docker` pode executar mais do que
apenas o aplicativo web:

- **Topolograph** aplicativo web + banco de dados.
- **Servidor MCP** em `http://localhost:8000/mcp` para
  [acesso de LLM/agente](../automation/mcp-server.md).
- **OSPF/IS-IS Watchers** opcionais e uma pilha **ELK** para
  [monitoramento em tempo real](../monitoring/index.md).

!!! note "Opção hospedada"
    Não quer auto-hospedar? Uma instância hospedada está disponível em
    [topolograph.com](https://topolograph.com). A versão Docker é ideal quando
    suas LSDBs não devem sair do seu ambiente.

---

**Próximo:** [Construa sua primeira topologia →](first-topology.md)

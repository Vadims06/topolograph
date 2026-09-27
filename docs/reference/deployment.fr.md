# Déploiement et configuration

Cette page rassemble les réglages de déploiement d'un Topolograph
auto-hébergé. Pour une première exécution pas à pas, voir le
[Démarrage rapide avec Docker](../getting-started/quickstart-docker.md).

## Installation

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d

!!! info "Pas d'analyse tierce"
    L'image Docker ne charge pas les compteurs Google Analytics et Yandex Metrika utilisés par topolograph.com.
# ou : sudo ./install.sh   (peut aussi démarrer les Watchers)
```

Ouvrez `http://localhost:8080/`.

## Variables d'environnement

La configuration se trouve dans `.env`, à côté de `docker-compose.yml`.

| Variable | Rôle |
| --- | --- |
| `TOPOLOGRAPH_PORT` | Port de l'interface web (par défaut `8080`). |
| `MCP_PORT` | Port du [serveur MCP](../automation/mcp-server.md) (par défaut `8000`). |
| `DNS` | IP du serveur DNS utilisé pour résoudre les router ID en noms d'équipements. |
| `DNS_LOOKUP_DEADLINE_SEC` | Durée maximale en secondes pendant laquelle un import attend les noms DNS (`5` par défaut). Les nœuds non résolus à temps gardent leur IP comme étiquette. |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL`, `TOPOLOGRAPH_WEB_API_PASSWORD` | Identifiants de l'API REST. |
| `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS` | Liste blanche des plages d'IP source autorisées pour les appels API. |
| `TOPOLOGRAPH_API_TOKEN` | Jeton pour authentifier les requêtes de l'API REST à la place d'un couple identifiant/mot de passe. |

Après toute modification, réappliquez avec `docker-compose up -d`.

### Variables côté Watcher

Lorsque vous exécutez aussi un [Watcher](../monitoring/index.md), son
`.env` ajoute quelques variables :

| Variable | Rôle |
| --- | --- |
| `TOPOLOGRAPH_HOST` | IP de l'hôte exécutant Topolograph. **N'utilisez pas `localhost`** — le Watcher, ELK et Topolograph tournent chacun dans leur propre espace réseau. |
| `TOPOLOGRAPH_PORT` | Port de Topolograph (par défaut `8080`). |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `_PASSWORD` | Utilisateur API sous lequel le Watcher publie (ex. `ospf@topolograph.com`). |
| `TEST_MODE` | Si `True`, rejoue des événements de démonstration depuis un fichier statique au lieu de lire l'IGP en direct. |
| `WATCHER_IP` | Remplace l'IP source rapportée par le Watcher (`srcid`) quand la résolution de nom d'hôte n'est pas fiable dans des conteneurs. |
| `EXPORT_TO_ELASTICSEARCH_BOOL`, `ELASTIC_IP` | Active et cible une pile [ELK](../monitoring/elk-kibana.md). |
| `EXPORT_TO_WEBHOOK_URL_BOOL`, `WEBHOOK_URL` | Active les notifications [WebHook/Slack](../monitoring/webhooks.md). |

## Créer les identifiants par défaut

Exécutez une fois pour créer l'utilisateur API à partir de votre `.env` et
charger les réseaux autorisés :

```python
import requests
print(requests.post('http://localhost:8080/create-default-credentials').json())
# {'errors': '', 'status': 'ok'}
```

Vérification : connectez-vous sur `http://localhost:8080/` via **Login →
Local login**, puis vérifiez **API → Authorised source IP ranges**.

## Ce que contient la stack

Le compose `topolograph-docker` peut exécuter, dans n'importe quelle
combinaison :

- **Topolograph** — application web + base de données
- **Serveur MCP** (`/mcp` sur `MCP_PORT`)
- **Watchers OSPF / IS-IS**
- Pile **ELK** pour la recherche d'événements

## Alternative hébergée

Une instance hébergée est disponible sur [topolograph.com](https://topolograph.com).
Choisissez l'auto-hébergement lorsque vos données LSDB doivent rester dans
votre environnement.

---

**Voir aussi :** [Démarrage rapide](../getting-started/quickstart-docker.md) ·
[Surveillance en temps réel](../monitoring/index.md)

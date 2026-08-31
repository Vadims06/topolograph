# Démarrage rapide avec Docker

La façon la plus rapide d'exécuter Topolograph est l'image Docker
auto-hébergée. Elle regroupe l'application web, sa base de données, et
(en option) le serveur MCP et les Watchers.

!!! tip "Prérequis"
    Installez **Docker** et **Docker Compose**. Sous Windows/macOS, Docker
    Desktop inclut les deux.

## 1. Cloner et démarrer

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
```

Vous préférez un installeur en une seule commande qui peut aussi démarrer les
Watchers ? Utilisez plutôt le script `install.sh` :

```bash
sudo ./install.sh
```

…ou exécutez-le directement depuis GitHub :

```bash
curl -O https://raw.githubusercontent.com/Vadims06/topolograph-docker/master/install.sh
chmod +x install.sh
sudo ./install.sh
```

Laissez-lui une minute ou deux pour démarrer, puis ouvrez :

```
http://localhost:8080/
```

## 2. Configurer avec `.env`

La configuration se trouve dans un fichier `.env` à côté de
`docker-compose.yml`. Les variables les plus utiles :

| Variable | Rôle |
| --- | --- |
| `TOPOLOGRAPH_PORT` | Port de l'interface web (`8080` par défaut). Ouvrez `http://localhost:<port>/` après redémarrage. |
| `DNS` | IP d'un serveur DNS, utilisée pour résoudre les identifiants de routeur en noms d'équipements sur le graphe. |
| `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL`, `TOPOLOGRAPH_WEB_API_PASSWORD` | Identifiants pour les requêtes de l'API REST. |
| `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS` | Liste blanche des plages d'IP source autorisées à appeler l'API. |
| `TOPOLOGRAPH_API_TOKEN` | Jeton pour authentifier les requêtes de l'API REST à la place d'un couple identifiant/mot de passe. |
| `MCP_PORT` | Port du [serveur MCP](../automation/mcp-server.md) intégré (`8000` par défaut). |

Après avoir modifié un port ou une autre valeur, réappliquez-la :

```bash
docker-compose up -d
```

## 3. Créer les identifiants par défaut

Pour créer l'utilisateur API à partir des valeurs de votre `.env` et charger
vos réseaux autorisés dans la liste blanche, envoyez cette requête une fois :

```python
import requests
res = requests.post('http://localhost:8080/create-default-credentials')
print(res.json())
# {'errors': '', 'status': 'ok'}
```

Vérifiez que cela a fonctionné :

1. Ouvrez `http://localhost:8080/` dans un navigateur.
2. Allez dans **Login → Local login** et connectez-vous avec
   `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` / `TOPOLOGRAPH_WEB_API_PASSWORD`.
3. L'onglet **API → Authorised source IP ranges** doit lister les plages de
   `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS`.

## Ce qui est inclus

Le `docker-compose.yml` de `topolograph-docker` peut exécuter plus que la
simple application web :

- **Topolograph** application web + base de données.
- **Serveur MCP** sur `http://localhost:8000/mcp` pour
  [l'accès LLM/agent](../automation/mcp-server.md).
- **OSPF/IS-IS Watchers** optionnels et une pile **ELK** pour la
  [surveillance en temps réel](../monitoring/index.md).

!!! note "Option hébergée"
    Vous ne voulez pas vous auto-héberger ? Une instance hébergée est
    disponible sur [topolograph.com](https://topolograph.com). La version
    Docker est idéale lorsque vos LSDB ne doivent pas quitter votre
    environnement.

---

**Suivant :** [Construisez votre première topologie →](first-topology.md)

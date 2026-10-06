# demo-api

Le fil rouge des quêtes Docker : une mini-API "catalogue" que tu vas
conteneuriser, faire persister, mettre en réseau, orchestrer et sécuriser,
une quête à la fois.

Le métier est volontairement trivial (`Node` + `Express` + `PostgreSQL`,
un catalogue de produits) : toute la difficulté est sur **Docker**, jamais
sur le code applicatif.

## Point de départ

Ce dossier est ce que tu clones **avant ta première quête Docker**. Il n'y a
volontairement **aucun fichier Docker** dedans, ni `Dockerfile`, ni
`compose.yml` : ce sont précisément les fichiers que tu vas écrire, quête
après quête, en faisant grossir ce dépôt.

Sans conteneur, cette API ne démarre pas telle quelle : elle a besoin d'un
PostgreSQL joignable pour répondre. C'est normal, et c'est tout le sujet
de la première quête que de la faire tourner dans Docker.

## Ce que contient le repo

| Fichier | Rôle |
|---|---|
| `api/server.js` | l'API Express (`/`, `/version`, `/health`, `/ready`, `/products`) |
| `api/db.js` | connexion PostgreSQL, entièrement pilotée par des variables d'environnement |
| `api/package.json`, `api/package-lock.json` | dépendances (`express`, `pg`) |
| `db/init.sql` | création de la table `products` + quelques données de démo |

## Les routes de l'API

| Méthode | Route | Effet |
|---|---|---|
| `GET` | `/` | infos application + version |
| `GET` | `/version` | numéro de version courant |
| `GET` | `/health` | liveness, ne touche pas la base |
| `GET` | `/ready` | readiness, teste la connexion à la base |
| `GET` | `/products` | liste des produits |
| `POST` | `/products` | crée un produit : `{ "name": "...", "price_cents": 1234 }` |

## Ta progression, quête après quête

| Quête | Ce que tu ajoutes au repo |
|---|---|
| Découverte de Docker | rien ici, tu manipules des images publiques et un `psql` en conteneur |
| Le Dockerfile | `api/Dockerfile`, `api/.dockerignore` : l'API tourne enfin dans un conteneur |
| Les volumes | un volume nommé pour la persistance de PostgreSQL |
| Les réseaux | des réseaux dédiés, la base jamais exposée directement |
| Compose | `compose.yml`, `.env.example` : tous les services démarrent ensemble |
| Dockerfile et sécurité | ton `Dockerfile` durci : utilisateur non-root, `HEALTHCHECK` |
| Builds multi-étapes et gestion des secrets | `api/Dockerfile.multi` : image allégée, secrets hors de l'image |
| Analyse de vulnérabilité avec Trivy | un pipeline CI qui scanne ton image et bloque sur les failles critiques |

## Prérequis machine (macOS / Linux / Windows)

- **Docker Engine + Compose v2** : le plugin intégré, invoqué en deux mots
  `docker compose` (pas l'ancien binaire autonome `docker-compose` v1).
  `docker compose version` doit répondre `v2.x` ou une version supérieure
  (v3, v4, v5…). Ce qui compte, c'est que ce ne soit pas du v1 legacy.
- macOS / Windows : **Docker Desktop** (ou Colima / Rancher Desktop).
  Sous Windows, backend **WSL 2** : travaille depuis un terminal **WSL**.
- `git`, `curl`. Node est nécessaire **seulement** si tu régénères
  `package-lock.json` (`cd api && npm install`, déjà commité ici).

---

# Rendu — Quête 2 : Le Dockerfile

## Objectif

Produire une image Docker de `demo-api` permettant de démarrer le serveur Node dans un conteneur.

## 1. Dockerfile

Le fichier `api/Dockerfile` a été créé avec :

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY server.js db.js ./
EXPOSE 3000
CMD ["node", "server.js"]
```

Le Dockerfile respecte les bonnes pratiques demandées :

- base légère avec `node:22-alpine` ;
- dépendances copiées avant le code ;
- installation avec `npm ci --omit=dev` ;
- port `3000` exposé ;
- lancement du serveur avec `CMD`.

## 2. .dockerignore

Le fichier `api/.dockerignore` contient :

```text
node_modules
.git
*.md
.env*
```

Il permet notamment d'exclure les dépendances locales, le dépôt Git, les fichiers Markdown et les fichiers d'environnement du contexte de build.

## 3. Construction de l'image

Commande utilisée :

```powershell
docker build -t demo-api:1.0 ./api
```

Résultat : build terminé avec succès.

Image obtenue :

```text
REPOSITORY   TAG   IMAGE ID       SIZE
demo-api     1.0   e035c32af65c   252MB
```

## 4. Test du conteneur

Le conteneur a été lancé avec :

```powershell
docker run -d --name api -p 8080:3000 demo-api:1.0
```

### Test de `/health`

Commande :

```powershell
curl.exe -s http://localhost:8080/health
```

Résultat :

```json
{"status":"UP"}
```

### Test de `/`

Commande :

```powershell
curl.exe -s http://localhost:8080/
```

Résultat :

```json
{"ok":true,"app":"demo-api","version":"dev"}
```

Le conteneur a ensuite été supprimé avec :

```powershell
docker rm -f api
```

## 5. Preuve du cache Docker

Après une modification temporaire de `server.js`, l'image a été reconstruite avec :

```powershell
docker build -t demo-api:1.0 ./api --progress=plain
```

La commande `npm ci` est restée en cache :

```text
#8 [4/5] RUN npm ci --omit=dev
#8 CACHED
```

La modification temporaire de `server.js` a ensuite été annulée avec :

```powershell
git restore api/server.js
```

## 6. Publication de l'image Docker Hub

L'image a été taguée avec :

```powershell
docker tag demo-api:1.0 mattlec/demo-api:1.0
```

Puis publiée avec :

```powershell
docker push mattlec/demo-api:1.0
```

Image Docker Hub :

https://hub.docker.com/r/mattlec/demo-api

## 7. Repository GitHub

La quête est disponible sur la branche :

https://github.com/ynov-x-anthony/tp-qu-tes-matt-correction/tree/quete-02-dockerfile

## Conclusion

- Dockerfile créé ;
- `.dockerignore` créé ;
- image Docker construite ;
- API testée avec succès ;
- cache Docker vérifié ;
- image publiée sur Docker Hub ;
- branche GitHub créée et poussée.
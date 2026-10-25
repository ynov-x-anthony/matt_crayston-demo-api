# Quête 7 — Docker Compose

## 1. Objectif

Orchestrer une application avec Docker Compose composée de trois services :

- **API** : application Node.js.
- **PostgreSQL** : base de données.
- **Adminer** : interface web d'administration de la base de données.

## 2. Prérequis

- Docker Desktop installé et démarré.
- Docker Compose disponible.

## 3. Configuration

Créer le fichier de configuration local :

```bash
cp .env.example .env
```

Créer le dossier des secrets et le fichier contenant le mot de passe PostgreSQL :

```bash
mkdir -p secrets
printf '%s' 'choisir-un-mot-de-passe-local' > secrets/postgres_password.txt
```

**Important :** remplacer `choisir-un-mot-de-passe-local` par un mot de passe de son choix. Ce mot de passe doit rester local et ne doit jamais être publié sur GitHub.

Le fichier `.env` et le dossier `secrets/` sont exclus du suivi Git. Le fichier `.env.example` est versionné.

## 4. Démarrage

Construire l'image de l'API et démarrer les services :

```bash
docker compose up -d --build
```

Vérifier leur état :

```bash
docker compose ps
```

### Résultat des tests

| Service | Image | État constaté | Accès |
|---|---|---|---|
| API | `docker-demo-api-starter-api` | `Up (healthy)` | `http://localhost:8080` |
| PostgreSQL | `postgres:16-alpine` | `Up (healthy)` | Réseau interne Docker |
| Adminer | `adminer:4` | `Up` | `http://localhost:8081` |

PostgreSQL n'expose pas son port directement sur la machine hôte.

## 5. Tester l'API

Lister les produits :

```bash
curl -s http://localhost:8080/products
```

Ajouter un produit :

```bash
curl -s -X POST http://localhost:8080/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Gourde","price_cents":900}'
```

Le test a retourné un produit nommé `Gourde`, avec l'identifiant `4` et un prix de `900` centimes.

## 6. Accéder à Adminer

Ouvrir `http://localhost:8081` dans un navigateur.

Paramètres de connexion :

- **Système** : PostgreSQL
- **Serveur** : `db`
- **Utilisateur** : `demo`
- **Mot de passe** : celui défini dans `secrets/postgres_password.txt`
- **Base de données** : `demo`

## 7. Persistance des données

Arrêter les services sans supprimer les volumes :

```bash
docker compose down
```

Redémarrer les services :

```bash
docker compose up -d
```

Vérifier les produits :

```bash
curl -s http://localhost:8080/products
```

**Résultat constaté :** la gourde, avec l'identifiant `4` et le prix de `900` centimes, était toujours présente après le redémarrage.

Le volume nommé `pgdata` conserve les données lorsque les conteneurs sont supprimés et recréés.

## 8. Arrêt et réinitialisation

Arrêter les services tout en conservant les données :

```bash
docker compose down
```

Pour supprimer également les volumes et les données qu'ils contiennent :

```bash
docker compose down -v
```

**Attention :** la commande `docker compose down -v` supprime les volumes du projet et les données associées.

## 9. Sécurité

- Les paramètres de configuration sont définis à l'aide de variables d'environnement.
- Le mot de passe PostgreSQL est transmis à l'aide d'un secret Docker Compose.
- L'API prend en charge `PGPASSWORD_FILE` pour lire le mot de passe depuis le fichier secret.
- `.env` et `secrets/` sont exclus du suivi Git.
- `.env.example` est versionné et ne contient aucun mot de passe réel.

## 10. Vérifications réalisées

- [x] Configuration validée avec `docker compose config --quiet`.
- [x] Démarrage réussi avec `docker compose up -d --build`.
- [x] PostgreSQL indiqué `healthy`.
- [x] API indiquée `healthy`.
- [x] API testée avec `GET /products`.
- [x] Produit ajouté avec `POST /products`.
- [x] Persistance vérifiée après `docker compose down`, puis `docker compose up -d`.
- [x] Mot de passe stocké dans un fichier secret local non versionné.
- [x] Documentation créée.
# app-matt

Mini API HTTP en Node.js sans dépendance externe, conçue pour démontrer les bonnes pratiques Docker, l'analyse de vulnérabilités avec Trivy et une CI GitHub Actions.

## Fonctionnalités

- `GET /health` : healthcheck, répond `{"status":"ok"}`.
- `GET /api/info` : informations non sensibles sur le service.
- Toute autre route retourne `404`.

## Prérequis

- Node.js 22 ou supérieur pour lancer les tests en local.
- Docker Desktop ou Docker Engine.
- Un dépôt GitHub pour exécuter la CI.

## Lancer les tests localement

```bash
npm ci
npm test
```

## Construire et lancer avec Docker

```bash
docker build --pull -t app-matt:local .
docker run --rm -d --name app-matt -p 3000:3000 app-matt:local
```

Tester l'API :

```bash
curl http://localhost:3000/health
curl http://localhost:3000/api/info
```

Vérifier l'utilisateur non-root et le healthcheck :

```bash
docker inspect --format='Utilisateur={{.Config.User}} | État={{.State.Status}} | Santé={{.State.Health.Status}}' app-matt
```

Arrêter le conteneur :

```bash
docker stop app-matt
```

## Scanner avec Trivy

Avec Trivy installé localement :

```bash
trivy image --severity HIGH,CRITICAL --ignore-unfixed app-matt:local
```

Ou avec Docker :

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --ignore-unfixed app-matt:local
```

La CI utilise `exit-code: 1` : elle échoue si Trivy trouve des vulnérabilités HIGH ou CRITICAL corrigibles. Le résultat dépend des vulnérabilités connues au moment du scan.

## Bonnes pratiques de sécurité appliquées

- Image basée sur `node:22-alpine`, relativement légère.
- Build multi-stage : les tests sont exécutés dans une étape séparée et ne sont pas copiés dans l'image finale.
- Image finale avec uniquement les dépendances de production.
- Processus exécuté avec l'utilisateur non privilégié `node`.
- Healthcheck intégré à l'image.
- `.dockerignore` exclut notamment `.env`, les secrets et les fichiers Git du contexte de build.
- Aucun secret n'est nécessaire au fonctionnement de cette API ; aucune clé ni aucun mot de passe n'est stocké dans le code ou l'image.
- En cas d'ajout futur de secrets CI, les stocker dans **Settings → Secrets and variables → Actions** sur GitHub, puis les référencer via `${{ secrets.NOM_DU_SECRET }}`. Ne jamais les écrire dans le dépôt.
- Workflow GitHub Actions déclenché sur les push et pull requests vers `main` : tests, build Docker et scan Trivy.

## Workflow Git recommandé

- `main` doit rester fonctionnelle.
- Créer une branche pour chaque changement, par exemple `feat/add-endpoint`.
- Ouvrir une Pull Request vers `main` et vérifier le statut de la CI avant fusion.

## Arborescence

```text
app-matt/
├── .github/workflows/ci.yml
├── src/server.js
├── test/server.test.js
├── .dockerignore
├── .gitignore
├── .env.example
├── Dockerfile
├── package.json
├── package-lock.json
└── README.md
```

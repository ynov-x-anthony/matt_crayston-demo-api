# Quête 8 — Sécurité des images Docker avec Trivy

## 1. Objectif

Analyser les vulnérabilités d'une image Docker avec Trivy, corriger les vulnérabilités identifiées et comparer les résultats des scans avant et après correction.

## 2. Prérequis

- Docker Desktop installé et démarré.
- Git disponible.
- Trivy, exécuté directement ou depuis son image Docker.

## 3. Construction de l'image

Construire l'image multi-stage de l'API :

```bash
docker build -f api/Dockerfile.multi -t demo-api:multi ./api
```

Le Dockerfile utilise deux étapes :

- **deps** : installation des dépendances de production avec `npm ci --omit=dev`.
- **runtime** : exécution de l'application avec l'utilisateur non privilégié `node`.

L'image finale ne conserve pas le répertoire global de npm :

```dockerfile
RUN rm -rf /usr/local/lib/node_modules/npm
```

## 4. Scan initial avec Trivy

Le rapport initial est conservé dans `scan-avant.txt`.

Pour analyser l'image et afficher les vulnérabilités de sévérité élevée ou critique :

```bash
MSYS_NO_PATHCONV=1 docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  demo-api:multi
```

## 5. Corrections réalisées

- Mise à jour de l'image de base Node.js vers `node:22-alpine`.
- Suppression de npm global dans l'étape finale de l'image.
- Mise à jour des dépendances dans `api/package-lock.json`, notamment `body-parser`.

Ces changements réduisent la surface d'attaque de l'image et corrigent les dépendances concernées.

## 6. Scan après correction

Le rapport après correction est conservé dans `scan-apres.txt`.

Commande utilisée :

```bash
MSYS_NO_PATHCONV=1 docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD:/work" \
  -w /work \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  --format table \
  demo-api:multi | tee scan-apres.txt
```

### Résultat constaté

Le scan après correction ne signale aucune vulnérabilité de sévérité **HIGH ou CRITICAL** dans l'image analysée.

Ce résultat concerne les niveaux de sévérité sélectionnés par la commande. Il ne signifie pas nécessairement qu'aucune vulnérabilité de sévérité inférieure n'existe.

## 7. Vérification du conteneur

Démarrer temporairement le conteneur :

```bash
docker run --rm -d --name demo-api-test -p 3000:3000 demo-api:multi
```

Vérifier son état et son healthcheck :

```bash
docker inspect --format="{{.State.Status}} | Health: {{if .State.Health}}{{.State.Health.Status}}{{else}}non configuré{{end}}" demo-api-test
```

**Résultat constaté :** `running | Health: healthy`.

Arrêter le conteneur :

```bash
docker stop demo-api-test
```

## 8. Rapports conservés

- `scan-avant.txt` : rapport du scan initial.
- `scan-apres.txt` : rapport après correction.

Ces rapports permettent de comparer les résultats avant et après les changements.

## 9. Vérifications réalisées

- [x] Image multi-stage construite.
- [x] Image exécutée avec l'utilisateur non privilégié `node`.
- [x] npm global supprimé de l'étape finale.
- [x] Dépendances mises à jour dans `api/package-lock.json`.
- [x] Scan Trivy initial conservé.
- [x] Scan Trivy après correction conservé.
- [x] Aucune vulnérabilité HIGH ou CRITICAL détectée dans le scan après correction.
- [x] Healthcheck du conteneur vérifié.
- [x] Documentation créée.
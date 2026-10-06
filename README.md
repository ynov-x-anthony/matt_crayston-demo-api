# Rendu — Quête 4 : Builds multi-étapes et gestion des secrets

## Objectif

Créer un Dockerfile multi-étapes pour `demo-api`, comparer les tailles des images et utiliser un secret au moment du build sans le faire apparaître dans l'image finale.

## 1. Dockerfile multi-étapes

Le fichier `api/Dockerfile.multi` a été créé avec deux étapes :

- `deps` : installation des dépendances de production ;
- `runtime` : image finale minimale contenant uniquement les éléments nécessaires à l'exécution.

```dockerfile
# syntax=docker/dockerfile:1

FROM node:22.11-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci --omit=dev

FROM node:22.11-alpine AS runtime
WORKDIR /app
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node server.js db.js package.json ./
USER node
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://localhost:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
EXPOSE 3000
CMD ["node", "server.js"]
```

## 2. Construction des images

Image de référence :

```powershell
docker build -t demo-api:naive ./api
```

Image multi-étapes :

```powershell
docker build -f api/Dockerfile.multi -t demo-api:multi ./api
```

## 3. Comparaison des tailles

Résultat obtenu :

```text
REPOSITORY   TAG        SIZE
demo-api     multi      228MB
demo-api     naive      232MB
```

Calcul du ratio :

```text
232 / 228 ≈ 1,02×
```

Le gain obtenu est donc d'environ 4 MB.

Le critère de la quête visant une image `multi` au moins 2× plus petite que `naive` n'est pas atteint dans cette configuration.

La raison est que l'image de départ utilise déjà `node:22.11-alpine` ainsi que `npm ci --omit=dev`. Le multi-étapes permet donc surtout de séparer les étapes de construction et d'exécution, mais ne permet pas ici de supprimer une quantité importante de données.

## 4. Vérification du fonctionnement

Le conteneur multi-étapes a été lancé avec :

```powershell
docker run --rm -d -p 8080:3000 --name api-multi-test demo-api:multi
```

Test de l'API :

```powershell
curl.exe -s http://localhost:8080/health
```

Résultat :

```json
{"status":"UP"}
```

L'image `demo-api:multi` fonctionne donc correctement.

## 5. Gestion du secret au build

Un faux fichier `.npmrc` a été créé temporairement :

```text
//registry.npmjs.org/:_authToken=FAKE-123
```

Le Dockerfile utilise ensuite BuildKit pour monter ce fichier uniquement pendant le `RUN` :

```dockerfile
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci --omit=dev
```

Le build a été réalisé avec :

```powershell
docker build --secret id=npmrc,src="$PWD\.npmrc" -f api/Dockerfile.multi -t demo-api:multi ./api
```

Le build s'est terminé avec succès.

## 6. Vérification du secret dans l'historique

Commande utilisée :

```powershell
docker history --no-trunc demo-api:multi | Select-String "FAKE-123"
```

Résultat :

```text
```

Aucune ligne n'est retournée.

Le token `FAKE-123` n'apparaît donc pas dans l'historique de l'image.

## 7. Vérification du fichier secret dans l'image

La présence de `/root/.npmrc` a été vérifiée avec :

```powershell
docker run --rm --entrypoint sh demo-api:multi -c "test -e /root/.npmrc && echo 'SECRET PRESENT' || echo 'SECRET ABSENT'"
```

Résultat :

```text
SECRET ABSENT
```

Le fichier contenant le secret n'est donc pas présent dans l'image finale.

## 8. Nettoyage du faux secret

Le fichier temporaire `.npmrc` a été supprimé :

```powershell
Remove-Item .npmrc
```

Vérification :

```powershell
Test-Path .npmrc
```

Résultat :

```text
False
```

Le faux secret n'est donc plus présent localement.

## Conclusion

- `api/Dockerfile.multi` créé avec un build multi-étapes ;
- étapes `deps` et `runtime` séparées ;
- image `demo-api:multi` fonctionnelle ;
- `/health` retourne `{"status":"UP"}` ;
- secret fourni avec `RUN --mount=type=secret` ;
- `FAKE-123` absent de `docker history` ;
- `/root/.npmrc` absent de l'image ;
- faux `.npmrc` supprimé après les tests ;
- taille obtenue : `228 MB` contre `232 MB` pour `naive` ;
- ratio obtenu : environ `1,02×`.
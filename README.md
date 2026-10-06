# Rendu — Quête 3 : Dockerfile et sécurité

## Objectif

Durcir le Dockerfile de `demo-api` et l'exécution du conteneur afin de réduire les privilèges et la surface d'attaque.

## 1. Dockerfile durci

Le fichier `api/Dockerfile` a été modifié avec :

```dockerfile
FROM node:22.11-alpine
WORKDIR /app
COPY --chown=node:node package.json package-lock.json ./
RUN npm ci --omit=dev
COPY --chown=node:node server.js db.js ./
USER node
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://localhost:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
EXPOSE 3000
CMD ["node", "server.js"]
```

Le Dockerfile respecte les consignes de sécurité :

- base épinglée `node:22.11-alpine` ;
- fichiers copiés avec `--chown=node:node` ;
- exécution avec l'utilisateur non-root `node` ;
- `HEALTHCHECK` configuré sur `/health` ;
- port `3000` exposé.

## 2. .dockerignore

Le fichier `api/.dockerignore` contient :

```text
node_modules
.git
*.md
.env*
```

Il exclut notamment les dépendances locales, le dépôt Git, les fichiers Markdown et les fichiers d'environnement.

## 3. Construction de l'image

Commande utilisée :

```powershell
docker build -t demo-api:hardened ./api
```

Le build s'est terminé avec succès et l'image `demo-api:hardened` a été créée.

## 4. Preuve du fonctionnement en non-root

Commande utilisée :

```powershell
docker run --rm demo-api:hardened id
```

Résultat :

```text
uid=1000(node) gid=1000(node) groups=1000(node)
```

Le conteneur s'exécute donc bien avec l'utilisateur non privilégié `node`.

## 5. Lancement du conteneur durci

Le conteneur a été lancé avec :

```powershell
docker run -d --name api -p 8080:3000 `
  --read-only --tmpfs /tmp:size=16m `
  --cap-drop ALL --security-opt no-new-privileges `
  --pids-limit 200 --memory 256m --cpus 1 `
  demo-api:hardened
```

Les principales protections activées sont :

- `--read-only` : système de fichiers du conteneur en lecture seule ;
- `--tmpfs /tmp:size=16m` : `/tmp` reste disponible en mémoire ;
- `--cap-drop ALL` : suppression de toutes les capabilities Linux ;
- `--security-opt no-new-privileges` : empêche l'escalade de privilèges ;
- `--pids-limit 200` : limite le nombre de processus ;
- `--memory 256m` : limite la mémoire ;
- `--cpus 1` : limite l'utilisation CPU.

## 6. Test de l'API

Commande :

```powershell
curl.exe -s http://localhost:8080/health
```

Résultat :

```json
{"status":"UP"}
```

L'API continue donc de fonctionner malgré le durcissement.

## 7. Vérification du HEALTHCHECK

Commande :

```powershell
docker ps
```

Résultat :

```text
CONTAINER ID   IMAGE               COMMAND                  CREATED          STATUS                    PORTS                    NAMES
2e8e9334ab88   demo-api:hardened   "docker-entrypoint.s…"   13 seconds ago   Up 12 seconds (healthy)   0.0.0.0:8080->3000/tcp   api
```

Docker indique donc que le conteneur est `healthy`.

## 8. Preuve du root filesystem en lecture seule

Commande :

```powershell
docker exec api sh -c 'touch /app/x 2>&1 || echo "rootfs read-only OK"'
```

Résultat :

```text
touch: /app/x: Read-only file system
rootfs
```

L'écriture dans `/app` est refusée : le root filesystem est bien en lecture seule.

## 9. Vérification du durcissement

Commande :

```powershell
docker inspect -f 'readonly={{.HostConfig.ReadonlyRootfs}} capdrop={{.HostConfig.CapDrop}}' api
```

Résultat :

```text
readonly=true capdrop=[ALL]
```

La configuration confirme donc :

- `ReadonlyRootfs=true` ;
- `CapDrop=[ALL]`.

## 10. Nettoyage

Après les tests, le conteneur a été supprimé avec :

```powershell
docker rm -f api
```

## Conclusion

- Dockerfile durci avec `node:22.11-alpine` ;
- exécution en utilisateur non-root ;
- `HEALTHCHECK` ajouté ;
- `.dockerignore` vérifié ;
- image `demo-api:hardened` construite ;
- API fonctionnelle sur `/health` ;
- root filesystem en lecture seule ;
- toutes les capabilities supprimées ;
- protections `no-new-privileges`, limites CPU/mémoire/PIDs activées ;
- preuves de sécurité vérifiées avec `docker inspect`.
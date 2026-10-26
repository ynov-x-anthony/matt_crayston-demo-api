# syntax=docker/dockerfile:1

# Étape 1 : installation et exécution des tests.
FROM node:22-alpine AS test
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY src ./src
COPY test ./test

RUN npm test

# Étape 2 : image d'exécution minimale.
FROM node:22-alpine AS runtime

# Suppression des gestionnaires de paquets inutiles à l'exécution.
RUN rm -rf /usr/local/lib/node_modules/npm \
    /usr/local/bin/npm \
    /usr/local/bin/npx

ENV NODE_ENV=production
ENV PORT=3000

WORKDIR /app

# Copie uniquement les fichiers nécessaires à l'exécution.
COPY --chown=node:node package.json ./package.json
COPY --chown=node:node src ./src

# Exécution avec un utilisateur non-root.
USER node

EXPOSE 3000

# Vérification automatique de l'état de santé du conteneur.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "src/server.js"] 
FROM node:22-alpine

ENV NODE_ENV=production
WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force

COPY --chown=node:node server.js ./

USER node

ENV PORT=4000
EXPOSE 4000

CMD ["npm", "start"]

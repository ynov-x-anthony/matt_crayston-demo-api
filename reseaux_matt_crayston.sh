#!/bin/bash
set -e

echo "=== 1. Construction de l'image API ==="
docker build -t demo-api:1.0 ./api

echo
echo "=== 2. Création des réseaux personnalisés ==="
docker network create demo_front
docker network create demo_back

echo
echo "=== 3. Démarrage de PostgreSQL sur demo_back uniquement ==="
MSYS_NO_PATHCONV=1 docker run -d --name demo-db \
  --network demo_back \
  -v "$(pwd)/db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro" \
  -e POSTGRES_USER=demo \
  -e POSTGRES_PASSWORD=demo \
  -e POSTGRES_DB=demo \
  postgres:16-alpine

echo
echo "=== 4. Attente de PostgreSQL ==="
until docker exec demo-db pg_isready -U demo; do
  sleep 1
done

echo
echo "=== 5. Démarrage de l'API sur les deux réseaux ==="
docker run -d --name demo-api \
  --network demo_back \
  -p 8080:3000 \
  -e PGHOST=demo-db \
  -e PGUSER=demo \
  -e PGPASSWORD=demo \
  -e PGDATABASE=demo \
  demo-api:1.0

docker network connect demo_front demo-api

sleep 2

echo
echo "=== 6. Vérification DNS depuis l'API ==="
docker exec demo-api getent hosts demo-db

echo
echo "=== 7. Vérification de l'isolation depuis demo_front ==="
if docker run --rm --network demo_front alpine:3.20 \
  sh -c 'nc -z -w 3 demo-db 5432'; then
  echo "ERREUR : le conteneur tiers peut joindre PostgreSQL."
  exit 1
else
  echo "SUCCÈS : le conteneur tiers ne peut pas joindre PostgreSQL."
fi

echo
echo "=== 8. Adresses IPv4 de demo-db ==="
docker inspect -f '{{range $name, $net := .NetworkSettings.Networks}}Réseau: {{$name}} - IPv4: {{$net.IPAddress}}{{"\n"}}{{end}}' demo-db

echo
echo "=== 9. Adresses IPv4 de demo-api ==="
docker inspect -f '{{range $name, $net := .NetworkSettings.Networks}}Réseau: {{$name}} - IPv4: {{$net.IPAddress}}{{"\n"}}{{end}}' demo-api

echo
echo "=== 10. Test de l'API ==="
curl -fsS localhost:8080/products
echo

echo
echo "=== 11. Nettoyage ==="
docker rm -f demo-api demo-db
docker network rm demo_front demo_back

echo
echo "=== FIN : vérifications terminées ==="

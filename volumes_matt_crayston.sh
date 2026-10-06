#!/bin/bash
set -e

docker build -t demo-api:1.0 ./api

docker volume create demo_pgdata
docker network create demo-network 2>/dev/null || true

MSYS_NO_PATHCONV=1 docker run -d --name demo-db \
  --network demo-network \
  -v demo_pgdata:/var/lib/postgresql/data \
  -v "$(pwd)/db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro" \
  -e POSTGRES_USER=demo \
  -e POSTGRES_PASSWORD=demo \
  -e POSTGRES_DB=demo \
  postgres:16-alpine

until docker exec demo-db pg_isready -U demo; do
  sleep 1
done

docker run -d --name demo-api \
  --network demo-network \
  -p 8080:3000 \
  -e PGHOST=demo-db \
  -e PGUSER=demo \
  -e PGPASSWORD=demo \
  -e PGDATABASE=demo \
  demo-api:1.0

sleep 2

curl -s -X POST -H 'content-type: application/json' \
  -d '{"name":"Casquette D\u00e9mo","price_cents":1200}' \
  localhost:8080/products

echo
echo "Produits avant suppression :"
curl -s localhost:8080/products
echo

docker rm -f demo-api
docker rm -f demo-db

MSYS_NO_PATHCONV=1 docker run -d --name demo-db \
  --network demo-network \
  -v demo_pgdata:/var/lib/postgresql/data \
  -v "$(pwd)/db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro" \
  -e POSTGRES_USER=demo \
  -e POSTGRES_PASSWORD=demo \
  -e POSTGRES_DB=demo \
  postgres:16-alpine

until docker exec demo-db pg_isready -U demo; do
  sleep 1
done

docker run -d --name demo-api \
  --network demo-network \
  -p 8080:3000 \
  -e PGHOST=demo-db \
  -e PGUSER=demo \
  -e PGPASSWORD=demo \
  -e PGDATABASE=demo \
  demo-api:1.0

sleep 2

echo "Produits apres suppression et recreation :"
curl -s localhost:8080/products
echo

echo "Volume utilise :"
docker volume ls | grep demo_pgdata

docker rm -f demo-api demo-db
docker network rm demo-network


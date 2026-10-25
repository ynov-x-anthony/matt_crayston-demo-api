# Rendu — Quête 6 : Réseaux Docker

## Objectif

Comprendre la communication entre conteneurs Docker, créer des réseaux personnalisés et isoler PostgreSQL afin qu'il ne soit accessible qu'aux conteneurs autorisés.

## 1. Construction de l'image API

L'image `demo-api:1.0` est construite à partir du dossier `api` :

```bash
docker build -t demo-api:1.0 ./api
```

La construction de l'image s'est terminée avec succès.

## 2. Création des réseaux personnalisés

Deux réseaux Docker sont créés :

```bash
docker network create demo_front
docker network create demo_back
```

- `demo_front` : réseau destiné à la partie frontale.
- `demo_back` : réseau utilisé pour la communication entre l'API et PostgreSQL.

Ces réseaux personnalisés permettent de contrôler quels conteneurs peuvent communiquer entre eux.

## 3. Lancement de PostgreSQL

Le conteneur `demo-db` est lancé sur le réseau `demo_back` uniquement.

Il utilise l'image :

```text
postgres:16-alpine
```

Les variables d'environnement sont :

```text
POSTGRES_USER=demo
POSTGRES_PASSWORD=demo
POSTGRES_DB=demo
```

Le fichier `db/init.sql` est monté en lecture seule dans le répertoire d'initialisation de PostgreSQL :

```text
/docker-entrypoint-initdb.d/init.sql
```

Ce fichier crée la table `products` et insère trois produits de démonstration.

Le script attend que PostgreSQL accepte les connexions :

```bash
until docker exec demo-db pg_isready -U demo; do
  sleep 1
done
```

Résultat obtenu :

```text
/var/run/postgresql:5432 - accepting connections
```

## 4. Lancement de l'API sur les deux réseaux

Le conteneur `demo-api` est démarré sur `demo_back`, puis connecté à `demo_front`.

La commande de connexion utilisée est :

```bash
docker network connect demo_front demo-api
```

L'API est publiée sur le port 8080 de la machine hôte :

```text
-p 8080:3000
```

La variable `PGHOST=demo-db` permet à l'API de retrouver PostgreSQL grâce au DNS Docker.

## 5. Vérification de la résolution DNS

La commande suivante est exécutée depuis le conteneur API :

```bash
docker exec demo-api getent hosts demo-db
```

Résultat obtenu :

```text
172.19.0.2        demo-db  demo-db
```

La résolution DNS fonctionne : l'API peut résoudre le nom `demo-db` sur le réseau partagé `demo_back`.

## 6. Vérification de l'isolation réseau

Un conteneur de test est lancé uniquement sur `demo_front` :

```bash
docker run --rm --network demo_front alpine:3.20 \
  sh -c 'nc -z -w 3 demo-db 5432'
```

Résultat obtenu :

```text
nc: bad address 'demo-db'
SUCCÈS : le conteneur tiers ne peut pas joindre PostgreSQL.
```

Le nom `demo-db` n'est pas résolu depuis ce conteneur, car il ne partage pas de réseau avec PostgreSQL.

Cette vérification confirme l'isolation DNS attendue entre les deux réseaux.

## 7. Vérification des adresses IPv4

Les adresses IP sont affichées avec `docker inspect`.

### Conteneur PostgreSQL

```text
Réseau: demo_back - IPv4: 172.19.0.2
```

Le conteneur `demo-db` est uniquement connecté à `demo_back`.

### Conteneur API

```text
Réseau: demo_back - IPv4: 172.19.0.3
Réseau: demo_front - IPv4: 172.18.0.2
```

Le conteneur `demo-api` possède une adresse IPv4 sur chacun des deux réseaux.

## 8. Vérification de l'API

La requête suivante est exécutée depuis la machine hôte :

```bash
curl -fsS localhost:8080/products
```

Résultat obtenu :

```json
[
  {
    "id": 3,
    "name": "T-shirt conteneur",
    "price_cents": 1990
  },
  {
    "id": 2,
    "name": "Mug Docker",
    "price_cents": 990
  },
  {
    "id": 1,
    "name": "Sticker Demo",
    "price_cents": 150
  }
]
```

L'API retourne bien les trois produits initialisés dans PostgreSQL.

## 9. Nettoyage

Une fois les vérifications terminées, le script supprime les conteneurs et les réseaux créés :

```bash
docker rm -f demo-api demo-db
docker network rm demo_front demo_back
```

Le nettoyage s'est terminé avec succès.

## 10. Script de la quête

Le script utilisé pour automatiser la démonstration est :

```text
reseaux_matt_crayston.sh
```

Il permet de :

- construire l'image `demo-api:1.0` ;
- créer les réseaux `demo_front` et `demo_back` ;
- lancer PostgreSQL uniquement sur `demo_back` ;
- attendre que PostgreSQL soit disponible ;
- lancer l'API sur les deux réseaux ;
- vérifier la résolution DNS ;
- tester l'isolation depuis `demo_front` ;
- afficher les adresses IPv4 ;
- tester l'endpoint `/products` ;
- nettoyer les conteneurs et les réseaux.

## Conclusion

La quête 6 démontre l'utilisation des réseaux personnalisés Docker :

- deux réseaux distincts sont créés ;
- PostgreSQL est isolé sur `demo_back` ;
- l'API est connectée à `demo_front` et `demo_back` ;
- la résolution DNS de `demo-db` fonctionne depuis l'API ;
- le conteneur de test sur `demo_front` ne résout pas le nom `demo-db` ;
- les adresses IPv4 sont affichées ;
- l'endpoint `/products` retourne les trois produits ;
- les conteneurs et les réseaux sont nettoyés à la fin du script.

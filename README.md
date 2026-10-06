# Rendu — Quête 5 : Les volumes Docker

## Objectif

Comprendre la persistance des données avec Docker, utiliser un volume nommé PostgreSQL et vérifier que les données restent présentes après la suppression et la recréation d'un conteneur.

## 1. Construction de l'image

L'image de l'API a été construite avec :

```bash
docker build -t demo-api:1.0 ./api
```

L'image `demo-api:1.0` a été créée avec succès.

## 2. Création du volume PostgreSQL

Un volume Docker nommé `demo_pgdata` est utilisé pour stocker les données PostgreSQL :

```bash
docker volume create demo_pgdata
```

Le volume est monté dans PostgreSQL avec :

```text
demo_pgdata:/var/lib/postgresql/data
```

Les données PostgreSQL sont donc stockées dans le volume et non dans la couche d'écriture temporaire du conteneur.

## 3. Lancement de PostgreSQL

Le conteneur `demo-db` utilise l'image :

```text
postgres:16-alpine
```

Il est lancé avec :

```text
POSTGRES_USER=demo
POSTGRES_PASSWORD=demo
POSTGRES_DB=demo
```

Le fichier `db/init.sql` est monté en lecture seule dans :

```text
/docker-entrypoint-initdb.d/init.sql
```

Le fichier crée la table `products` et ajoute trois produits de démonstration.

## 4. Attente de disponibilité de PostgreSQL

Le script attend que PostgreSQL accepte les connexions avec :

```bash
until docker exec demo-db pg_isready -U demo; do
  sleep 1
done
```

Le résultat obtenu confirme que PostgreSQL accepte les connexions :

```text
/var/run/postgresql:5432 - accepting connections
```

## 5. Lancement de l'API

Le conteneur `demo-api` est lancé sur le même réseau Docker que PostgreSQL.

La variable :

```text
PGHOST=demo-db
```

permet à l'API de communiquer avec le conteneur PostgreSQL via son nom Docker.

Le port de l'API est exposé avec :

```text
-p 8080:3000
```

## 6. Ajout d'un produit

Le script ajoute le produit demandé :

```json
{
  "name": "Casquette Démo",
  "price_cents": 1200
}
```

Le produit a été créé avec l'identifiant `4`.

## 7. Vérification avant suppression

Avant la suppression des conteneurs, la requête `/products` retourne notamment :

```json
{
  "id": 4,
  "name": "Casquette Démo",
  "price_cents": 1200
}
```

Les trois produits initialisés par `init.sql` sont également présents.

## 8. Suppression des conteneurs

Les conteneurs `demo-api` et `demo-db` ont ensuite été supprimés :

```bash
docker rm -f demo-api
docker rm -f demo-db
```

Le volume `demo_pgdata` n'a pas été supprimé.

## 9. Recréation de PostgreSQL et de l'API

Le conteneur PostgreSQL a été recréé en utilisant exactement le même volume :

```text
demo_pgdata:/var/lib/postgresql/data
```

L'API a ensuite été recréée et reconnectée à PostgreSQL.

PostgreSQL est de nouveau devenu disponible :

```text
/var/run/postgresql:5432 - accepting connections
```

## 10. Preuve de persistance

Après la suppression et la recréation du conteneur PostgreSQL, la requête `/products` retourne toujours :

```json
{
  "id": 4,
  "name": "Casquette Démo",
  "price_cents": 1200
}
```

La donnée `Casquette Démo` a donc survécu à la suppression et à la recréation du conteneur PostgreSQL.

## 11. Vérification du volume

Le volume est toujours présent :

```text
local     demo_pgdata
```

Cela confirme que les données étaient stockées dans le volume nommé `demo_pgdata`.

## 12. Script de la quête

Le script automatisant l'ensemble de la démonstration est :

```text
volumes_matt_crayston.sh
```

Il permet de :

- construire l'image `demo-api:1.0` ;
- créer le volume `demo_pgdata` ;
- créer le réseau Docker ;
- lancer PostgreSQL ;
- attendre que PostgreSQL soit disponible ;
- lancer l'API ;
- ajouter `Casquette Démo` ;
- afficher les produits avant suppression ;
- supprimer les conteneurs ;
- recréer PostgreSQL avec le même volume ;
- recréer l'API ;
- afficher les produits après recréation ;
- vérifier la présence du volume ;
- nettoyer les conteneurs et le réseau.

## Conclusion

La Quête 5 est validée :

- volume nommé `demo_pgdata` créé ;
- PostgreSQL configuré avec ce volume ;
- API connectée à PostgreSQL ;
- produit `Casquette Démo` ajouté ;
- conteneur PostgreSQL supprimé ;
- conteneur PostgreSQL recréé avec le même volume ;
- `Casquette Démo` toujours présente après recréation ;
- volume `demo_pgdata` vérifié ;
- script `volumes_matt_crayston.sh` fonctionnel.
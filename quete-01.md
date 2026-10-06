# Quête 1 — Découverte Docker

## Réalisation

- Vérification de Docker avec `docker version` : Client et Server opérationnels.
- Test `docker run --rm hello-world` : installation Docker validée.
- Création du conteneur PostgreSQL `demo-db` avec PostgreSQL 16 Alpine.
- Création de la table `products`.
- Insertion du produit `Sticker Démo` au prix de 150 centimes.

## Résultat de `\dt`

    Schema |   Name   | Type  | Owner
    ------- | -------- | ----- | -----
    public | products | table | demo

## Résultat de `SELECT * FROM products;`

    id |     name     | price_cents
    ---|--------------|------------
    1  | Sticker Démo | 150

## Logs PostgreSQL

Le serveur PostgreSQL affiche : `database system is ready to accept connections`.


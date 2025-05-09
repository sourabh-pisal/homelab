#!/bin/bash

# Exit immediately
set -e 

# Update to latest version
docker compose pull

# Create docker containers without running them
docker compose create

# Start Postgres server
docker start immich_postgres

# Wait for Postgres server to start up
sleep 10

# Check the database user if you deviated from the default
gunzip --stdout "backup.sql.gz" \
| sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" \
| docker exec -i immich_postgres psql --dbname=postgres --username=postgres

# Start remaining containers
docker compose up -d

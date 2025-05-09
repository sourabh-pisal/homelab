#!/bin/bash

# Exit immediately
set -e 

# Backup from immich_postgress to current directory
docker exec -t immich_postgres pg_dumpall --clean --if-exists --username=postgres | gzip > "backup.sql.gz"

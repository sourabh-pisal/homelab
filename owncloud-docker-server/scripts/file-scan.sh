#!/bin/bash

# Exit immediately
set -e 

# Run files scan
docker exec -it owncloud_server occ files:scan --all

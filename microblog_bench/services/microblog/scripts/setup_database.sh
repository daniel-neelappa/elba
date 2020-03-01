#!/bin/bash

# Change to the parent directory.
cd "$(dirname "$(dirname "$(readlink -fm "$0")")")"

# Set up the database.
psql -h $1 -d microblog_bench -f data/schema.sql

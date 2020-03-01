#!/bin/bash

# Change to the parent directory.
cd "$(dirname "$(dirname "$(readlink -fm "$0")")")"

# Create configuration directory.
mkdir -p conf

# Render postgresql.conf.
sed "s/{{MAXCONNECTIONS}}/$POSTGRES_MAXCONNECTIONS/g" templates/postgresql.conf > conf/postgresql.conf

# Copy and edit pg_hba.conf.
cat templates/pg_hba.conf > conf/pg_hba.conf
echo "host    all   all   0.0.0.0/0   trust" >> conf/pg_hba.conf
echo "host    all   all   ::/0        trust" >> conf/pg_hba.conf

# Set Postgres configuration.
sudo cp conf/postgresql.conf /etc/postgresql/10/main/
sudo cp conf/pg_hba.conf /etc/postgresql/10/main/

# Restart Postgres.
sudo service postgresql restart

#!/bin/bash

# Change to this directory.
cd $(dirname "$(readlink -fm "$0")")

# Start server.
./gen_code.sh $1
./setup_database.sh
./start_server.sh $1 localhost 9090 32
sleep 1

# Run unit tests.
python ../test/$1/unit.py

# Stop server.
./stop_server.sh

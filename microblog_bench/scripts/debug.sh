#!/bin/bash

# This script has the following software dependencies:
#   - thrift
#   - postgresql-10
#   - postgresql-client-10
#   - Python 3 environment with the packages in requirements.txt

# Parameters:
#   1. Thread pool size of each microservice.
#   2. Num of workers.

# Change to the WISE_HOME directory.
cd "$(dirname "$(dirname "$(dirname "$(readlink -fm "$0")")")")"

# Set parameters.
export THRIFT_THREADPOOLSIZE=$1
export NUM_WORKERS=$2

# Export global variables.
export WISE_DEBUG=1
export WISE_HOME=$(pwd)
export POSTGRESQL_HOST=localhost
export AUTH_HOSTS=localhost
export AUTH_PORT=9090
export INBOX_HOSTS=localhost
export INBOX_PORT=9091
export MICROBLOG_HOSTS=localhost
export MICROBLOG_PORT=9092
export QUEUE_HOSTS=localhost
export QUEUE_PORT=9093
export SUB_HOSTS=localhost
export SUB_PORT=9094

# Set PYTHONPATH.
export PYTHONPATH=$WISE_HOME/WISELoad/include/
export PYTHONPATH=$WISE_HOME/WISEServices/auth/include/py/:$PYTHONPATH
export PYTHONPATH=$WISE_HOME/WISEServices/inbox/include/py/:$PYTHONPATH
export PYTHONPATH=$WISE_HOME/WISEServices/queue_/include/py/:$PYTHONPATH
export PYTHONPATH=$WISE_HOME/WISEServices/sub/include/py/:$PYTHONPATH
export PYTHONPATH=$WISE_HOME/microblog_bench/services/microblog/include/py/:$PYTHONPATH

# Set up the database.
dropdb --if-exists microblog_bench
sudo -u postgres psql -c "DROP ROLE $(whoami)"
sudo -u postgres psql -c "CREATE ROLE $(whoami) WITH LOGIN CREATEDB SUPERUSER"
createdb microblog_bench

# Set up authentication microservice.
$WISE_HOME/WISEServices/auth/scripts/gen_code.sh py
$WISE_HOME/WISEServices/auth/scripts/setup_database.sh $POSTGRESQL_HOST
$WISE_HOME/WISEServices/auth/scripts/start_server.sh py $AUTH_HOSTS $AUTH_PORT $THRIFT_THREADPOOLSIZE $POSTGRESQL_HOST

# Set up inbox microservice.
$WISE_HOME/WISEServices/inbox/scripts/gen_code.sh py
$WISE_HOME/WISEServices/inbox/scripts/setup_database.sh $POSTGRESQL_HOST
$WISE_HOME/WISEServices/inbox/scripts/start_server.sh py $INBOX_HOSTS $INBOX_PORT $THRIFT_THREADPOOLSIZE $POSTGRESQL_HOST

# Set up queue microservice.
$WISE_HOME/WISEServices/queue_/scripts/gen_code.sh py
$WISE_HOME/WISEServices/queue_/scripts/setup_database.sh $POSTGRESQL_HOST
$WISE_HOME/WISEServices/queue_/scripts/start_server.sh py $QUEUE_HOSTS $QUEUE_PORT $THRIFT_THREADPOOLSIZE $POSTGRESQL_HOST

# Set up subscription microservice.
$WISE_HOME/WISEServices/sub/scripts/gen_code.sh py
$WISE_HOME/WISEServices/sub/scripts/setup_database.sh $POSTGRESQL_HOST
$WISE_HOME/WISEServices/sub/scripts/start_server.sh py $SUB_HOSTS $SUB_PORT $THRIFT_THREADPOOLSIZE $POSTGRESQL_HOST

# Set up microblog microservice.
$WISE_HOME/microblog_bench/services/microblog/scripts/gen_code.sh py
$WISE_HOME/microblog_bench/services/microblog/scripts/setup_database.sh $POSTGRESQL_HOST
$WISE_HOME/microblog_bench/services/microblog/scripts/start_server.sh py $MICROBLOG_HOSTS $MICROBLOG_PORT $THRIFT_THREADPOOLSIZE $POSTGRESQL_HOST

# Set up worker.
$WISE_HOME/microblog_bench/worker/scripts/start_workers.sh

# Set up web server.
$WISE_HOME/microblog_bench/web/scripts/start_server.sh local

# Wait servers.
sleep 8

# Run unit tests.
echo "Running unit tests for the authentication microservice..."
python $WISE_HOME/WISEServices/auth/test/py/unit.py
echo "Running unit tests for the inbox microservice..."
python $WISE_HOME/WISEServices/inbox/test/py/unit.py
echo "Running unit tests for the queue microservice..."
python $WISE_HOME/WISEServices/queue_/test/py/unit.py
echo "Running unit tests for the subscription microservice..."
python $WISE_HOME/WISEServices/sub/test/py/unit.py
echo "Running unit tests for the microblog microservice..."
python $WISE_HOME/microblog_bench/services/microblog/test/py/unit.py

# Render workload.yml.
ESCAPED_WISE_HOME=${WISE_HOME//\//\\\/}
sed -i "s/{{WISEHOME}}/$ESCAPED_WISE_HOME/g" $WISE_HOME/experiment/conf/workload.yml

# Generate requests.
echo "Generating requests..."
python $WISE_HOME/microblog_bench/client/session.py --config $WISE_HOME/experiment/conf/workload.yml --hostname localhost --port 5000

# Stop workers.
$WISE_HOME/microblog_bench/worker/scripts/stop_workers.sh

# Stop web server.
$WISE_HOME/microblog_bench/web/scripts/stop_server.sh local

# Stop microservices.
$WISE_HOME/WISEServices/auth/scripts/stop_server.sh
$WISE_HOME/WISEServices/inbox/scripts/stop_server.sh
$WISE_HOME/WISEServices/queue_/scripts/stop_server.sh
$WISE_HOME/WISEServices/sub/scripts/stop_server.sh
$WISE_HOME/microblog_bench/services/microblog/scripts/stop_server.sh

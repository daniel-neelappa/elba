#!/bin/bash

# Change to the parent directory.
cd $(dirname "$(dirname "$(readlink -fm "$0")")")


# Source configuration file.
source conf/config.sh


# Copy variables.
all_hosts="$CLIENT_HOSTS $WEB_HOSTS $POSTGRESQL_HOST $WORKER_HOSTS $MICROBLOG_HOSTS $AUTH_HOSTS $INBOX_HOSTS $QUEUE_HOSTS $SUB_HOSTS"





#Container Common Setup Commands

echo "Container Commands Next"

##Ignore container commands if docker is not chosen
if [[ $CONTAINER_TYPE == "Docker" ]]; then
    
    wise_home="/root/elba"
    echo "Docker Chosen"
    CONTAINER_COMMON_COMMANDS="
# Synchronize apt.
    apt-get install -y sudo
    sudo apt-get update
  
    # Install Thrift
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y automake bison flex g++ git libboost-all-dev libevent-dev libssl-dev libtool make pkg-config
    tar -xzf $wise_home/experiment/artifacts/thrift-0.13.0.tar.gz -C .
    cd thrift-0.13.0
    ./bootstrap.sh
    ./configure --without-python
    make
    sudo make install

    # Install Collectl.
    cd $fs_rootdir
    tar -xzf $wise_home/experiment/artifacts/collectl-4.3.1.src.tar.gz -C .
    cd collectl-4.3.1
    sudo ./INSTALL

    # Set up Python 3 environment.
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y virtualenv
    virtualenv -p `which python3` $wise_home/.env
"

else
    CONTAINER_COMMON_COMMANDS=""
    echo "Docker Not Chosen"
fi

commd="cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys"


#Container Setup
if [[ "$CONTAINER_TYPE" == "Docker" ]]; then
  echo "[$(date +%s)] Database Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $POSTGRESQL_HOST; do
    echo "  [$(date +%s)] Setting up Container database server on host $host"
    echo "$wise_home"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $POSTGRESQL_SSH:22 -p $POSTGRESQL_PORT:$POSTGRESQL_PORT -d --cpuset-cpus $POSTGRESQL_CPU --name postgresql harvardbiodept/nucleus
      sudo docker cp ~/.ssh/id_rsa.pub postgresql:/root/.ssh/
      sudo docker cp ~/.ssh/id_rsa postgresql:/root/.ssh/
      sudo docker cp -a ~/elba postgresql:/root/
      sudo docker exec --user root postgresql bash -c $'$commd'
      
      

    " &
    sessions[$n_sessions]=$!
    let n_sessions=n_sessions+1
  done
  for session in ${sessions[*]}; do
    wait $session
  done
fi

echo "[$(date +%s)] Database setup:"
sessions=()
n_sessions=0
for host in $POSTGRESQL_HOST; do
  echo "  [$(date +%s)] Setting up database server on host $host"
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $CONTAINER_USERNAME@$host -p $POSTGRESQL_SSH "
      $CONTAINER_COMMON_COMMANDS
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-10
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-common
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-10

    export POSTGRES_MAXCONNECTIONS="$POSTGRES_MAXCONNECTIONS"

    $wise_home/microblog_bench/postgres/scripts/start_postgres.sh
    sudo -u postgres psql -c \"CREATE ROLE $CONTAINER_USERNAME WITH LOGIN CREATEDB SUPERUSER\"
    createdb microblog_bench
  " &
  sessions[$n_sessions]=$!
  let n_sessions=n_sessions+1
done
for session in ${sessions[*]}; do
  wait $session
done
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
  echo "[$(date +%s)] Auth Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $AUTH_HOSTS; do
    echo "  [$(date +%s)] Setting up Container auth server on host $host"
    echo "$wise_home"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $AUTH_SSH:22 -p $AUTH_PORT:$AUTH_PORT -d --cpuset-cpus $AUTH_CPU --name auth harvardbiodept/nucleus
      sudo docker cp ~/.ssh/id_rsa.pub auth:/root/.ssh/
      sudo docker cp ~/.ssh/id_rsa auth:/root/.ssh/
      sudo docker cp -a ~/elba auth:/root/
      sudo docker exec --user root auth bash -c $'$commd'
      
      

    " &
    sessions[$n_sessions]=$!
    let n_sessions=n_sessions+1
  done
  for session in ${sessions[*]}; do
    wait $session
  done
fi





echo "[$(date +%s)] Authentication microservice setup:"
sessions=()
n_sessions=0
for host in $AUTH_HOSTS; do
  echo "  [$(date +%s)] Setting up authentication microservice on host $host"

  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $CONTAINER_USERNAME@$host -p $AUTH_SSH "
      $CONTAINER_COMMON_COMMANDS
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-common
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-10

    # Install Python dependencies.
    source $wise_home/.env/bin/activate
    pip install click
    pip install psycopg2-binary
    pip install thrift

    # Generate Thrift code.
    $wise_home/WISEServices/auth/scripts/gen_code.sh py

    # Setup database.
    $wise_home/WISEServices/auth/scripts/setup_database.sh $POSTGRESQL_HOST

    # Export configuration parameters.
    export WISE_DEBUG=$WISE_DEBUG

    $wise_home/WISEServices/auth/scripts/start_server.sh py 0.0.0.0 $AUTH_PORT $AUTH_THREADPOOLSIZE $POSTGRESQL_HOST
  " &
  sessions[$n_sessions]=$!
  let n_sessions=n_sessions+1
done
for session in ${sessions[*]}; do
  wait $session
done
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
  echo "[$(date +%s)] web Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $WEB_HOSTS; do
    echo "  [$(date +%s)] Setting up Container web server on host $host"
    echo "$wise_home"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $WEB_SSH:22 -p $WEB_PORT:$WEB_PORT -d --cpuset-cpus $WEB_CPU --name web harvardbiodept/nucleus
      sudo docker cp ~/.ssh/id_rsa.pub web:/root/.ssh/
      sudo docker cp ~/.ssh/id_rsa web:/root/.ssh/
      sudo docker cp -a ~/elba web:/root/
      sudo docker exec --user root web bash -c $'$commd'
      
      

    " &
    sessions[$n_sessions]=$!
    let n_sessions=n_sessions+1
  done
  for session in ${sessions[*]}; do
    wait $session
  done
fi


echo "[$(date +%s)] Web setup:"
sessions=()
n_sessions=0
for host in $WEB_HOSTS; do
  echo "  [$(date +%s)] Setting up web server on host $host"

  APACHE_WSGIDIRPATH=$wise_home/microblog_bench/web/src
  APACHE_PYTHONPATH=$wise_home/WISEServices/auth/include/py/
  APACHE_PYTHONPATH=$wise_home/WISEServices/inbox/include/py/:$APACHE_PYTHONPATH
  APACHE_PYTHONPATH=$wise_home/WISEServices/queue_/include/py/:$APACHE_PYTHONPATH
  APACHE_PYTHONPATH=$wise_home/WISEServices/sub/include/py/:$APACHE_PYTHONPATH
  APACHE_PYTHONPATH=$wise_home/microblog_bench/services/microblog/include/py/:$APACHE_PYTHONPATH
  APACHE_PYTHONHOME=$wise_home/.env
  APACHE_WSGIDIRPATH=${APACHE_WSGIDIRPATH//\//\\\\\/}
  APACHE_PYTHONPATH=${APACHE_PYTHONPATH//\//\\\\\/}
  APACHE_PYTHONHOME=${APACHE_PYTHONHOME//\//\\\\\/}

  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $CONTAINER_USERNAME@$host -p $WEB_SSH "
      $CONTAINER_COMMON_COMMANDS
    # Install Apache/mod_wsgi.
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apache2
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apache2-dev
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libapache2-mod-wsgi-py3

    # Install Python dependencies.
    source $wise_home/.env/bin/activate
    pip install flask
    pip install flask_httpauth
    pip install pyyaml
    pip install thrift
    deactivate

    # Generate Thrift code.
    $wise_home/WISEServices/auth/scripts/gen_code.sh py
    $wise_home/WISEServices/inbox/scripts/gen_code.sh py
    $wise_home/WISEServices/queue_/scripts/gen_code.sh py
    $wise_home/WISEServices/sub/scripts/gen_code.sh py
    $wise_home/microblog_bench/services/microblog/scripts/gen_code.sh py

    # Export configuration parameters.
    export APACHE_WSGIDIRPATH="$APACHE_WSGIDIRPATH"
    export APACHE_PYTHONPATH="$APACHE_PYTHONPATH"
    export APACHE_PYTHONHOME="$APACHE_PYTHONHOME"
    export APACHE_PROCESSES=$APACHE_PROCESSES
    export APACHE_THREADSPERPROCESS=$APACHE_THREADSPERPROCESS
    export APACHE_WSGIFILENAME=web.wsgi
    export AUTH_HOSTS=$AUTH_HOSTS
    export AUTH_PORT=$AUTH_PORT
    export INBOX_HOSTS=$INBOX_HOSTS
    export INBOX_PORT=$INBOX_PORT
    export MICROBLOG_HOSTS=$MICROBLOG_HOSTS
    export MICROBLOG_PORT=$MICROBLOG_PORT
    export QUEUE_HOSTS=$QUEUE_HOSTS
    export QUEUE_PORT=$QUEUE_PORT
    export SUB_HOSTS=$SUB_HOSTS
    export SUB_PORT=$SUB_PORT

    $wise_home/microblog_bench/web/scripts/start_server.sh apache
  " &
  sessions[$n_sessions]=$!
  let n_sessions=n_sessions+1
done
for session in ${sessions[*]}; do
  wait $session
done
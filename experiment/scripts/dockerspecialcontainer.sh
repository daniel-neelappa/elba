
#!/bin/bash

# Change to the parent directory.
cd $(dirname "$(dirname "$(readlink -fm "$0")")")


# Source configuration file.
source conf/config.sh


# Copy variables.
all_hosts="$CLIENT_HOSTS $WEB_HOSTS $POSTGRESQL_HOST $WORKER_HOSTS $MICROBLOG_HOSTS $AUTH_HOSTS $INBOX_HOSTS $QUEUE_HOSTS $SUB_HOSTS"

if [[ $HOSTS_TYPE = "vm" ]]; then
  fs_rootdir="/experiment"
else
  fs_rootdir="/mnt/experiment"
fi

wise_home="$fs_rootdir/elba"


echo "[$(date +%s)] Authentication microservice setup:"
sessions=()
n_sessions=0
for host in $AUTH_HOSTS; do
  echo "  [$(date +%s)] Setting up authentication microservice on host $host"

  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host  "
      sudo docker run --rm -p $AUTH_PORT:$AUTH_PORT -d --cpuset-cpus $AUTH_CPU --name auth harvardbiodept/auth:latest $AUTH_PORT $AUTH_THREADPOOLSIZE $POSTGRESQL_HOST
  " &
  sessions[$n_sessions]=$!
  let n_sessions=n_sessions+1
done
for session in ${sessions[*]}; do
  wait $session
done




#Container Setup
if ["$CONTAINER_TYPE" == "Docker"]; then
  echo "[$(date +%s)] Inbox Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $INBOX_HOSTS; do
    echo "  [$(date +%s)] Setting up Container Inbox server on host $host"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $INBOX_PORT:$INBOX_PORT -d --cpuset-cpus $INBOX_CPU --name inbox harvardbiodept/inbox:latest $INBOX_PORT $INBOX_THREADPOOLSIZE $POSTGRESQL_HOST
    " &
    sessions[$n_sessions]=$!
    let n_sessions=n_sessions+1
  done
  for session in ${sessions[*]}; do
    wait $session
  done
fi
 

#Container Setup
if ["$CONTAINER_TYPE" == "Docker"]; then
  echo "[$(date +%s)] Queue box Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $QUEUE_HOSTS; do
    echo "  [$(date +%s)] Setting up Container Queue server on host $host"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $QUEUE_PORT:$QUEUE_PORT -d --cpuset-cpus $QUEUE_CPU --name inbox harvardbiodept/inbox:latest $INBOX_PORT $INBOX_THREADPOOLSIZE $POSTGRESQL_HOST
    " &
    sessions[$n_sessions]=$!
    let n_sessions=n_sessions+1
  done
  for session in ${sessions[*]}; do
    wait $session
  done
fi

#Container Setup
if ["$CONTAINER_TYPE" == "Docker"]; then
  echo "[$(date +%s)] Subscription Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $SUB_HOSTS; do
    echo "  [$(date +%s)] Setting up Container Sub server on host $host"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $SUB_PORT:$SUB_PORT -d --cpuset-cpus $SUB_CPU --name sub harvardbiodept/sub:latest $SUB_PORT $SUB_THREADPOOLSIZE $POSTGRESQL_HOST
    " &
    sessions[$n_sessions]=$!
    let n_sessions=n_sessions+1
  done
  for session in ${sessions[*]}; do
    wait $session
  done
fi




echo "[$(date +%s)] Microblog microservice setup:"
sessions=()
n_sessions=0
for host in $MICROBLOG_HOSTS; do
  echo "  [$(date +%s)] Setting up microblog microservice on host $host"

  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host  "
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-common
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-10

    # Install Python dependencies.
    source $wise_home/.env/bin/activate
    pip install click
    pip install psycopg2-binary
    pip install thrift

    # Generate Thrift code.
    $wise_home/microblog_bench/services/microblog/scripts/gen_code.sh py

    # Setup database.
    $wise_home/microblog_bench/services/microblog/scripts/setup_database.sh $POSTGRESQL_HOST

    # Export configuration parameters.
    export WISE_DEBUG=$WISE_DEBUG

    $wise_home/microblog_bench/services/microblog/scripts/start_server.sh py 0.0.0.0 $MICROBLOG_PORT $MICROBLOG_THREADPOOLSIZE $POSTGRESQL_HOST
  " &
  sessions[$n_sessions]=$!
  let n_sessions=n_sessions+1
done
for session in ${sessions[*]}; do
  wait $session
done
 


echo "[$(date +%s)] Worker setup:"
sessions=()
n_sessions=0
for host in $WORKER_HOSTS; do
  echo "  [$(date +%s)] Setting up worker on host $host"

  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host  "
    # Install Python dependencies.
    source $wise_home/.env/bin/activate
    pip install pyyaml
    pip install thrift

    # Generate Thrift code.
    $wise_home/WISEServices/inbox/scripts/gen_code.sh py
    $wise_home/WISEServices/queue_/scripts/gen_code.sh py
    $wise_home/WISEServices/sub/scripts/gen_code.sh py

    # Export configuration parameters.
    export NUM_WORKERS=$NUM_WORKERS
    export INBOX_HOSTS=$INBOX_HOSTS
    export INBOX_PORT=$INBOX_PORT
    export QUEUE_HOSTS=$QUEUE_HOSTS
    export QUEUE_PORT=$QUEUE_PORT
    export SUB_HOSTS=$SUB_HOSTS
    export SUB_PORT=$SUB_PORT
    export WISE_HOME=$wise_home
    export WISE_DEBUG=$WISE_DEBUG

    $wise_home/microblog_bench/worker/scripts/start_workers.sh
  " &
  sessions[$n_sessions]=$!
  let n_sessions=n_sessions+1
done
for session in ${sessions[*]}; do
  wait $session
done
 


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
      -o BatchMode=yes $USERNAME@$host  "
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

 

echo "[$(date +%s)] Client setup:"
sessions=()
n_sessions=0
for host in $CLIENT_HOSTS; do
  echo "  [$(date +%s)] Setting up client on host $host"
  scp -P $CLIENT_SSH -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no conf/workload.yml $CONTAINER_USERNAME@$host:$wise_home/experiment/conf
  scp -P $CLIENT_SSH -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no conf/session.yml $CONTAINER_USERNAME@$host:$wise_home/experiment/conf
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host  "
    # Install Python dependencies.
    source $wise_home/.env/bin/activate
    pip install click
    pip install requests
    pip install pyyaml
    deactivate

    # Render workload.yml.
    WISEHOME=${wise_home//\//\\\\\/}
    sed -i \"s/{{WISEHOME}}/\$WISEHOME/g\" $wise_home/experiment/conf/workload.yml
  " &
  sessions[$n_sessions]=$!
  let n_sessions=n_sessions+1
done
for session in ${sessions[*]}; do
  wait $session
done
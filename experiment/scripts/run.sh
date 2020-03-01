#!/bin/bash

# Change to the parent directory.
cd $(dirname "$(dirname "$(readlink -fm "$0")")")


# Source configuration file.
source conf/config.sh


# Copy variables.
all_hosts="$CLIENT_HOSTS $WEB_HOSTS $POSTGRESQL_HOST $WORKER_HOSTS $MICROBLOG_HOSTS $AUTH_HOSTS $INBOX_HOSTS $QUEUE_HOSTS $SUB_HOSTS"





echo "[$(date +%s)] Common software setup:"
wise_home="$fs_rootdir/elba"
sessions=()
n_sessions=0
for host in $all_hosts; do
  echo "  [$(date +%s)] Setting up common software in host $host"
  scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/.ssh/id_rsa $USERNAME@$host:.ssh
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o \
      BatchMode=yes $USERNAME@$host "
    # Synchronize apt.
    sudo apt-get update

    # Clone WISETutorial.
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git
    ssh-keyscan -H github.com >> ~/.ssh/known_hosts
    rm -rf WISETutorial
    git clone git@github.com:daniel-neelappa/elba.git
    rm -rf $wise_home
    mv WISETutorial $fs_rootdir

    #Install Docker
    sudo apt-get install -y docker.io


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
  " &
  sessions[$n_sessions]=$!
  let n_sessions=n_sessions+1
done
for session in ${sessions[*]}; do
  wait $session
done

echo "Container Commands Next"

#Container Common Setup Commands
CONTAINER_COMMON_COMMANDS="
# Synchronize apt.
    apt-get install -y sudo
    sudo apt-get update
    mkdir -p $fs_rootdir

    # Clone WISETutorial.
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git
    ssh-keyscan -H github.com >> ~/.ssh/known_hosts
    rm -rf WISETutorial
    git clone git@github.com:daniel-neelappa/elba.git
    rm -rf $wise_home
    mv WISETutorial $fs_rootdir



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
echo "Container Commands Next"
##Ignore container commands if docker is not chosen
if ["$CONTAINER_TYPE" == "Docker"]; then
CONTAINER_COMMON_COMMANDS=""

echo "Container Commands Next"
#Container Setup
if ["$CONTAINER_TYPE" == "Docker"]; then
  echo "[$(date +%s)] Database Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $POSTGRESQL_HOST; do
    echo "  [$(date +%s)] Setting up Container database server on host $host"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $POSTGRESQL_SSH:22 -p $POSTGRESQL_PORT:$POSTGRESQL_PORT -d --cpuset-cpus $POSTGRESQL_CPU --name postgresql harvardbiodept/nucleus
      sudo docker cp ~/.ssh/id_rsa.pub postgresql:/root/.ssh/
      sudo docker exec -w /root/.ssh postgresql bash -c "cat id_rsa.pub >> authorized_keys"

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



#Container Setup
if ["$CONTAINER_TYPE" == "Docker"]; then
  echo "[$(date +%s)] Authentication Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $AUTH_HOSTS; do
    echo "  [$(date +%s)] Setting up Container Authentication microservice server on host $host"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $AUTH_SSH:22 -p $AUTH_PORT:$AUTH_PORT -d --cpuset-cpus $AUTH_CPU --name auth harvardbiodept/nucleus
      sudo docker cp ~/.ssh/id_rsa.pub auth:/root/.ssh/
      sudo docker exec -w /root/.ssh auth bash -c "cat id_rsa.pub >> authorized_keys"
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




#Container Setup
if ["$CONTAINER_TYPE" == "Docker"]; then
  echo "[$(date +%s)] Inbox Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $INBOX_HOSTS; do
    echo "  [$(date +%s)] Setting up Container Inbox server on host $host"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $INBOX_SSH:22 -p $INBOX_PORT:$INBOX_PORT -d --cpuset-cpus $INBOX_CPU --name inbox harvardbiodept/nucleus
      sudo docker cp ~/.ssh/id_rsa.pub inbox:/root/.ssh/
      sudo docker exec -w /root/.ssh inbox bash -c "cat id_rsa.pub >> authorized_keys"
    " &
    sessions[$n_sessions]=$!
    let n_sessions=n_sessions+1
  done
  for session in ${sessions[*]}; do
    wait $session
  done
fi

echo "[$(date +%s)] Inbox microservice setup:"
sessions=()
n_sessions=0
for host in $INBOX_HOSTS; do
  echo "  [$(date +%s)] Setting up inbox microservice on host $host"

  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $CONTAINER_USERNAME@$host -p $INBOX_SSH "
      $CONTAINER_COMMON_COMMANDS
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-common
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-10

    # Install Python dependencies.
    source $wise_home/.env/bin/activate
    pip install click
    pip install psycopg2-binary
    pip install thrift

    # Generate Thrift code.
    $wise_home/WISEServices/inbox/scripts/gen_code.sh py

    # Setup database.
    $wise_home/WISEServices/inbox/scripts/setup_database.sh $POSTGRESQL_HOST

    # Export configuration parameters.
    export WISE_DEBUG=$WISE_DEBUG

    $wise_home/WISEServices/inbox/scripts/start_server.sh py 0.0.0.0 $INBOX_PORT $INBOX_THREADPOOLSIZE $POSTGRESQL_HOST
  " &
  sessions[$n_sessions]=$!
  let n_sessions=n_sessions+1
done
for session in ${sessions[*]}; do
  wait $session
done

#Container Setup
if ["$CONTAINER_TYPE" == "Docker"]; then
  echo "[$(date +%s)] Queue box Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $QUEUE_HOSTS; do
    echo "  [$(date +%s)] Setting up Container Queue server on host $host"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $QUEUE_SSH:22 -p $QUEUE_PORT:$QUEUE_PORT -d --cpuset-cpus $QUEUE_CPU --name queue harvardbiodept/nucleus
      sudo docker cp ~/.ssh/id_rsa.pub queue:/root/.ssh/
      sudo docker exec -w /root/.ssh queue bash -c "cat id_rsa.pub >> authorized_keys"
    " &
    sessions[$n_sessions]=$!
    let n_sessions=n_sessions+1
  done
  for session in ${sessions[*]}; do
    wait $session
  done
fi

echo "[$(date +%s)] Queue microservice setup:"
sessions=()
n_sessions=0
for host in $QUEUE_HOSTS; do
  echo "  [$(date +%s)] Setting up queue microservice on host $host"

  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $CONTAINER_USERNAME@$host -p $QUEUE_SSH "
      $CONTAINER_COMMON_COMMANDS
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-common
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-10

    # Install Python dependencies.
    source $wise_home/.env/bin/activate
    pip install click
    pip install psycopg2-binary
    pip install thrift

    # Generate Thrift code.
    $wise_home/WISEServices/queue_/scripts/gen_code.sh py

    # Setup database.
    $wise_home/WISEServices/queue_/scripts/setup_database.sh $POSTGRESQL_HOST

    # Export configuration parameters.
    export WISE_DEBUG=$WISE_DEBUG

    $wise_home/WISEServices/queue_/scripts/start_server.sh py 0.0.0.0 $QUEUE_PORT $QUEUE_THREADPOOLSIZE $POSTGRESQL_HOST
  " &
  sessions[$n_sessions]=$!
  let n_sessions=n_sessions+1
done
for session in ${sessions[*]}; do
  wait $session
done

#Container Setup
if ["$CONTAINER_TYPE" == "Docker"]; then
  echo "[$(date +%s)] Subscription Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $SUB_HOSTS; do
    echo "  [$(date +%s)] Setting up Container Sub server on host $host"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $SUB_SSH:22 -p $SUB_PORT:$SUB_PORT -d --cpuset-cpus $SUB_CPU --name sub harvardbiodept/nucleus
      sudo docker cp ~/.ssh/id_rsa.pub sub:/root/.ssh/
      sudo docker exec -w /root/.ssh sub bash -c "cat id_rsa.pub >> authorized_keys"
    " &
    sessions[$n_sessions]=$!
    let n_sessions=n_sessions+1
  done
  for session in ${sessions[*]}; do
    wait $session
  done
fi

echo "[$(date +%s)] Subscription microservice setup:"
sessions=()
n_sessions=0
for host in $SUB_HOSTS; do
  echo "  [$(date +%s)] Setting up subscription microservice on host $host"

  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $CONTAINER_USERNAME@$host -p $SUB_SSH "
      $CONTAINER_COMMON_COMMANDS
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-common
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-10

    # Install Python dependencies.
    source $wise_home/.env/bin/activate
    pip install click
    pip install psycopg2-binary
    pip install thrift

    # Generate Thrift code.
    $wise_home/WISEServices/sub/scripts/gen_code.sh py

    # Setup database.
    $wise_home/WISEServices/sub/scripts/setup_database.sh $POSTGRESQL_HOST

    # Export configuration parameters.
    export WISE_DEBUG=$WISE_DEBUG

    $wise_home/WISEServices/sub/scripts/start_server.sh py 0.0.0.0 $SUB_PORT $SUB_THREADPOOLSIZE $POSTGRESQL_HOST
  " &
  sessions[$n_sessions]=$!
  let n_sessions=n_sessions+1
done
for session in ${sessions[*]}; do
  wait $session
done

#Container Setup
if ["$CONTAINER_TYPE" == "Docker"]; then
  echo "[$(date +%s)] Microblog Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $MICROBLOG_HOSTS; do
    echo "  [$(date +%s)] Setting up Container Microblog server on host $host"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $MICROBLOG_SSH:22 -p $MICROBLOG_PORT:$MICROBLOG_PORT -d --cpuset-cpus $MICROBLOG_CPU --name microblog harvardbiodept/nucleus
      sudo docker cp ~/.ssh/id_rsa.pub microblog:/root/.ssh/
      sudo docker exec -w /root/.ssh microblog bash -c "cat id_rsa.pub >> authorized_keys"
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
      -o BatchMode=yes $CONTAINER_USERNAME@$host -p $MICROBLOG_SSH "
      $CONTAINER_COMMON_COMMANDS
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

#Container Setup
if ["$CONTAINER_TYPE" == "Docker"]; then
  echo "[$(date +%s)] Worker Setup Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $WORKER_HOSTS; do
    echo "  [$(date +%s)] Setting up Container Worker server on host $host"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $WORKER_SSH:22 -d --cpuset-cpus $WORKER_CPU --name worker harvardbiodept/nucleus
      sudo docker cp ~/.ssh/id_rsa.pub worker:/root/.ssh/
      sudo docker exec -w /root/.ssh worker bash -c "cat id_rsa.pub >> authorized_keys"
    " &
    sessions[$n_sessions]=$!
    let n_sessions=n_sessions+1
  done
  for session in ${sessions[*]}; do
    wait $session
  done
fi


echo "[$(date +%s)] Worker setup:"
sessions=()
n_sessions=0
for host in $WORKER_HOSTS; do
  echo "  [$(date +%s)] Setting up worker on host $host"

  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $CONTAINER_USERNAME@$host -p $WORKER_SSH "
      $CONTAINER_COMMON_COMMANDS
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

#Container Setup
if ["$CONTAINER_TYPE" == "Docker"]; then
  echo "[$(date +%s)] Web Setup Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $WEB_HOSTS; do
    echo "  [$(date +%s)] Setting up Container Web server on host $host"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $WEB_SSH:22 -p $WEB_PORT:$WEB_PORT -d --cpuset-cpus $WEB_CPU --name web harvardbiodept/nucleus
      sudo docker cp ~/.ssh/id_rsa.pub web:/root/.ssh/
      sudo docker exec -w /root/.ssh web bash -c "cat id_rsa.pub >> authorized_keys"
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


#Container Setup
if ["$CONTAINER_TYPE" == "Docker"]; then
  echo "[$(date +%s)] Client Setup Container setup on host:"
  sessions=()
  n_sessions=0
  for host in $CLIENT_HOSTS; do
    echo "  [$(date +%s)] Setting up Container Client server on host $host"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        -o BatchMode=yes $USERNAME@$host "
      sudo docker run --rm -p $CLIENT_SSH:22 -d --cpuset-cpus $CLIENT_CPU --name client harvardbiodept/nucleus
      sudo docker cp ~/.ssh/id_rsa.pub client:/root/.ssh/
      sudo docker exec -w /root/.ssh client bash -c "cat id_rsa.pub >> authorized_keys"
    " &
    sessions[$n_sessions]=$!
    let n_sessions=n_sessions+1
  done
  for session in ${sessions[*]}; do
    wait $session
  done
fi

echo "[$(date +%s)] Client setup:"
sessions=()
n_sessions=0
for host in $CLIENT_HOSTS; do
  echo "  [$(date +%s)] Setting up client on host $host"
  scp -P $CLIENT_SSH -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no conf/workload.yml $CONTAINER_USERNAME@$host:$wise_home/experiment/conf
  scp -P $CLIENT_SSH -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no conf/session.yml $CONTAINER_USERNAME@$host:$wise_home/experiment/conf
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $CONTAINER_USERNAME@$host -p $CLIENT_SSH "
      $CONTAINER_COMMON_COMMANDS
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


echo "[$(date +%s)] Processor setup:"
if [[ $HOSTS_TYPE = "physical" ]]; then
  if [[ $HARDWARE_TYPE = "c8220" ]]; then
  for host in $all_hosts; do
    echo "  [$(date +%s)] Disabling cores in host $host"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o \
        BatchMode=yes $USERNAME@$host "
      for i in \$(seq 4 39); do echo 0 | sudo tee /sys/devices/system/cpu/cpu\$i/online; done
    "
  done
  fi
  if [[ $HARDWARE_TYPE = "d430" ]]; then
  for host in $all_hosts; do
    echo "  [$(date +%s)] Disabling cores in host $host"
    ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o \
        BatchMode=yes $USERNAME@$host "
      for i in \$(seq 4 31); do echo 0 | sudo tee /sys/devices/system/cpu/cpu\$i/online; done
    "
  done
  fi
fi


echo "[$(date +%s)] System instrumentation:"
sessions=()
n_sessions=0
for host in $all_hosts; do
  echo "  [$(date +%s)] Instrumenting host $host"
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host "
    # Activate WISETrace.
    cd $wise_home/WISETrace/kernel_modules/connect
    make
    sudo insmod spec_connect.ko
    cd $wise_home/WISETrace/kernel_modules/sendto
    make
    sudo insmod spec_sendto.ko
    cd $wise_home/WISETrace/kernel_modules/recvfrom
    make
    sudo insmod spec_recvfrom.ko

    # Activate Collectl.
    cd $wise_home
    mkdir -p collectl/data
    nohup sudo nice -n -1 /usr/bin/collectl -sCDmnt -i.05 -oTm -P -f collectl/data/coll > /dev/null 2>&1 &
  " &
  sessions[$n_sessions]=$!
  let n_sessions=n_sessions+1
done
for session in ${sessions[*]}; do
  wait $session
done


sleep 16


echo "[$(date +%s)] Benchmark execution:"
sessions=()
n_sessions=0
for host in $CLIENT_HOSTS; do
  echo "  [$(date +%s)] Generating requests from host $host"
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host "
    source $wise_home/.env/bin/activate

    # Set PYTHONPATH.
    export PYTHONPATH=$wise_home/WISELoad/include/:$PYTHONPATH

    # Export configuration parameters.
    export WISE_DEBUG=$WISE_DEBUG

    # [TODO] Load balance.
    mkdir -p $wise_home/logs
    python $wise_home/microblog_bench/client/session.py --config $wise_home/experiment/conf/workload.yml --hostname $WEB_HOSTS --port 80 --prefix microblog > $wise_home/logs/session.log
  " &
  sessions[$n_sessions]=$!
  let n_sessions=n_sessions+1
done
for session in ${sessions[*]}; do
  wait $session
done


echo "[$(date +%s)] Client tear down:"
for host in $CLIENT_HOSTS; do
  echo "  [$(date +%s)] Tearing down client on host $host"
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host "
    # Stop resource monitors.
    sudo pkill collectl
    sleep 8

    # Collect log data.
    mkdir logs
    mv $wise_home/collectl/data/coll-* logs/
    gzip -d logs/coll-*
    cat /proc/spec_connect > logs/spec_connect.csv
    cat /proc/spec_sendto > logs/spec_sendto.csv
    cat /proc/spec_recvfrom > logs/spec_recvfrom.csv
    tar -C logs -czf log-client-\$(echo \$(hostname) | awk -F'[-.]' '{print \$1\$2}').tar.gz ./

    # Stop event monitors.
    sudo rmmod spec_connect
    sudo rmmod spec_sendto
    sudo rmmod spec_recvfrom
  "
done


echo "[$(date +%s)] Web tear down:"
for host in $WEB_HOSTS; do
  echo "  [$(date +%s)] Tearing down web server on host $host"
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host "
    # Stop server.
    $wise_home/microblog_bench/web/scripts/stop_server.sh apache

    # Stop resource monitors.
    sudo pkill collectl
    sleep 8

    # Collect log data.
    mkdir logs
    mv $wise_home/collectl/data/coll-* logs/
    gzip -d logs/coll-*
    cat /proc/spec_connect > logs/spec_connect.csv
    cat /proc/spec_sendto > logs/spec_sendto.csv
    cat /proc/spec_recvfrom > logs/spec_recvfrom.csv
    tar -C logs -czf log-web-\$(echo \$(hostname) | awk -F'[-.]' '{print \$1\$2}').tar.gz ./

    # Stop event monitors.
    sudo rmmod spec_connect
    sudo rmmod spec_sendto
    sudo rmmod spec_recvfrom
  "
done


echo "[$(date +%s)] Worker tear down:"
for host in $WORKER_HOSTS; do
  echo "  [$(date +%s)] Tearing down workers on host $host"
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host "
    # Stop server.
    $wise_home/microblog_bench/worker/scripts/stop_workers.sh

    # Stop resource monitors.
    sudo pkill collectl
    sleep 8

    # Collect log data.
    mkdir logs
    mv $wise_home/collectl/data/coll-* logs/
    gzip -d logs/coll-*
    cat /proc/spec_connect > logs/spec_connect.csv
    cat /proc/spec_sendto > logs/spec_sendto.csv
    cat /proc/spec_recvfrom > logs/spec_recvfrom.csv
    tar -C logs -czf log-worker-\$(echo \$(hostname) | awk -F'[-.]' '{print \$1\$2}').tar.gz ./

    # Stop event monitors.
    sudo rmmod spec_connect
    sudo rmmod spec_sendto
    sudo rmmod spec_recvfrom
  "
done


echo "[$(date +%s)] Microblog microservice tear down:"
for host in $MICROBLOG_HOSTS; do
  echo "  [$(date +%s)] Tearing down microblog microservice on host $host"
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host "
    # Stop server.
    $wise_home/microblog_bench/services/microblog/scripts/stop_server.sh

    # Stop resource monitors.
    sudo pkill collectl
    sleep 8

    # Collect log data.
    mkdir logs
    mv $wise_home/collectl/data/coll-* logs/
    gzip -d logs/coll-*
    cat /proc/spec_connect > logs/spec_connect.csv
    cat /proc/spec_sendto > logs/spec_sendto.csv
    cat /proc/spec_recvfrom > logs/spec_recvfrom.csv
    tar -C logs -czf log-microblog-\$(echo \$(hostname) | awk -F'[-.]' '{print \$1\$2}').tar.gz ./

    # Stop event monitors.
    sudo rmmod spec_connect
    sudo rmmod spec_sendto
    sudo rmmod spec_recvfrom
  "
done


echo "[$(date +%s)] Subscription microservice tear down:"
for host in $SUB_HOSTS; do
  echo "  [$(date +%s)] Tearing down subscription microservice on host $host"
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host "
    # Stop server.
    $wise_home/WISEServices/sub/scripts/stop_server.sh

    # Stop resource monitors.
    sudo pkill collectl
    sleep 8

    # Collect log data.
    mkdir logs
    mv $wise_home/collectl/data/coll-* logs/
    gzip -d logs/coll-*
    cat /proc/spec_connect > logs/spec_connect.csv
    cat /proc/spec_sendto > logs/spec_sendto.csv
    cat /proc/spec_recvfrom > logs/spec_recvfrom.csv
    tar -C logs -czf log-sub-\$(echo \$(hostname) | awk -F'[-.]' '{print \$1\$2}').tar.gz ./

    # Stop event monitors.
    sudo rmmod spec_connect
    sudo rmmod spec_sendto
    sudo rmmod spec_recvfrom
  "
done


echo "[$(date +%s)] Queue microservice tear down:"
for host in $QUEUE_HOSTS; do
  echo "  [$(date +%s)] Tearing down queue microservice on host $host"
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host "
    # Stop server.
    $wise_home/WISEServices/queue_/scripts/stop_server.sh

    # Stop resource monitors.
    sudo pkill collectl
    sleep 8

    # Collect log data.
    mkdir logs
    mv $wise_home/collectl/data/coll-* logs/
    gzip -d logs/coll-*
    cat /proc/spec_connect > logs/spec_connect.csv
    cat /proc/spec_sendto > logs/spec_sendto.csv
    cat /proc/spec_recvfrom > logs/spec_recvfrom.csv
    tar -C logs -czf log-queue-\$(echo \$(hostname) | awk -F'[-.]' '{print \$1\$2}').tar.gz ./

    # Stop event monitors.
    sudo rmmod spec_connect
    sudo rmmod spec_sendto
    sudo rmmod spec_recvfrom
  "
done


echo "[$(date +%s)] Inbox microservice tear down:"
for host in $INBOX_HOSTS; do
  echo "  [$(date +%s)] Tearing down inbox microservice on host $host"
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host "
    # Stop server.
    $wise_home/WISEServices/inbox/scripts/stop_server.sh

    # Stop resource monitors.
    sudo pkill collectl
    sleep 8

    # Collect log data.
    mkdir logs
    mv $wise_home/collectl/data/coll-* logs/
    gzip -d logs/coll-*
    cat /proc/spec_connect > logs/spec_connect.csv
    cat /proc/spec_sendto > logs/spec_sendto.csv
    cat /proc/spec_recvfrom > logs/spec_recvfrom.csv
    tar -C logs -czf log-inbox-\$(echo \$(hostname) | awk -F'[-.]' '{print \$1\$2}').tar.gz ./

    # Stop event monitors.
    sudo rmmod spec_connect
    sudo rmmod spec_sendto
    sudo rmmod spec_recvfrom
  "
done


echo "[$(date +%s)] Authentication microservice tear down:"
for host in $AUTH_HOSTS; do
  echo "  [$(date +%s)] Tearing down authentication microservice on host $host"
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host "
    # Stop server.
    $wise_home/WISEServices/auth/scripts/stop_server.sh

    # Stop resource monitors.
    sudo pkill collectl
    sleep 8

    # Collect log data.
    mkdir logs
    mv $wise_home/collectl/data/coll-* logs/
    gzip -d logs/coll-*
    cat /proc/spec_connect > logs/spec_connect.csv
    cat /proc/spec_sendto > logs/spec_sendto.csv
    cat /proc/spec_recvfrom > logs/spec_recvfrom.csv
    tar -C logs -czf log-auth-\$(echo \$(hostname) | awk -F'[-.]' '{print \$1\$2}').tar.gz ./

    # Stop event monitors.
    sudo rmmod spec_connect
    sudo rmmod spec_sendto
    sudo rmmod spec_recvfrom
  "
done


echo "[$(date +%s)] Database tear down:"
for host in $POSTGRESQL_HOST; do
  echo "  [$(date +%s)] Tearing down database server on host $host"
  ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      -o BatchMode=yes $USERNAME@$host "
    # Stop server.
    $wise_home/microblog_bench/postgres/scripts/stop_postgres.sh

    # Stop resource monitors.
    sudo pkill collectl
    sleep 8

    # Collect log data.
    mkdir logs
    mv $wise_home/collectl/data/coll-* logs/
    gzip -d logs/coll-*
    cat /proc/spec_connect > logs/spec_connect.csv
    cat /proc/spec_sendto > logs/spec_sendto.csv
    cat /proc/spec_recvfrom > logs/spec_recvfrom.csv
    tar -C logs -czf log-db-\$(echo \$(hostname) | awk -F'[-.]' '{print \$1\$2}').tar.gz ./

    # Stop event monitors.
    sudo rmmod spec_connect
    sudo rmmod spec_sendto
    sudo rmmod spec_recvfrom
  "
done


echo "[$(date +%s)] Log data collection:"
for host in $all_hosts; do
  echo "  [$(date +%s)] Collecting log data from host $host"
  scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $USERNAME@$host:log-*.tar.gz .
done
tar -czf results.tar.gz log-*.tar.gz conf/


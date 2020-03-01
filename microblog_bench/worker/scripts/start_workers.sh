#!/bin/bash

# Change to the parent directory.
cd "$(dirname "$(dirname "$(readlink -fm "$0")")")"

# Set Python flags.
if [ $WISE_DEBUG -eq 1 ]; then
  PYFLAGS="-u"
else
  PYFLAGS=""
fi

# Create configuration directory.
mkdir -p conf

# Render services.yml.
echo "inbox:" > conf/services.yml
for inbox_host in $INBOX_HOSTS; do
  echo "  - hostname: $inbox_host" >> conf/services.yml
  echo "    port: $INBOX_PORT" >> conf/services.yml
done
echo "queue:" >> conf/services.yml
for queue_host in $QUEUE_HOSTS; do
  echo "  - hostname: $queue_host" >> conf/services.yml
  echo "    port: $QUEUE_PORT" >> conf/services.yml
done
echo "subscription:" >> conf/services.yml
for subscription_host in $SUB_HOSTS; do
  echo "  - hostname: $subscription_host" >> conf/services.yml
  echo "    port: $SUB_PORT" >> conf/services.yml
done

# Set PYTHONPATH.
export PYTHONPATH=$WISE_HOME/WISEServices/inbox/include/py/:$PYTHONPATH
export PYTHONPATH=$WISE_HOME/WISEServices/queue_/include/py/:$PYTHONPATH
export PYTHONPATH=$WISE_HOME/WISEServices/sub/include/py/:$PYTHONPATH

# Start the workers.
rm -f pid
rm -rf logs
mkdir -p logs
for workerno in $(seq 1 $NUM_WORKERS); do
  echo "[$(date +"%s")] Initializing worker ${workerno}..."
  nohup python $PYFLAGS src/worker.py > logs/worker${workerno}.log 2>&1 &
  echo "$!" >> pid
done

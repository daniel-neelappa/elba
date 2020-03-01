#!/bin/bash

# Change to the parent directory.
cd "$(dirname "$(dirname "$(readlink -fm "$0")")")"

# Set debug flags.
if [ $WISE_DEBUG -eq 1 ]; then
  PYFLAGS="-u"
else
  PYFLAGS=""
fi

# Start the server.
if [ $1 = "py" ]
then
  mkdir -p logs
  nohup python $PYFLAGS src/py/server.py --ip_address $2 --port $3 --thread_pool_size $4 --db_host $5 > logs/error.log 2>&1 &
  echo "$!" > pid
fi

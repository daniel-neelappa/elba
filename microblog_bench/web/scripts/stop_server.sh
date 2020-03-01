#!/bin/bash

if [ $1 = "apache" ]; then
  # Stop Apache.
  sudo service apache2 stop
else
  # Change to the parent directory.
  cd "$(dirname "$(dirname "$(readlink -fm "$0")")")"
  # Stop flask server.
  xargs kill < pid
  rm pid
fi

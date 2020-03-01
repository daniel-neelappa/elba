#!/bin/bash

# Change to the parent directory.
cd "$(dirname "$(dirname "$(readlink -fm "$0")")")"

# Create configuration directory.
mkdir -p conf

# Render services.yml.
echo "authentication:" > conf/services.yml
for authentication_host in $AUTH_HOSTS; do
  echo "  - hostname: $authentication_host" >> conf/services.yml
  echo "    port: $AUTH_PORT" >> conf/services.yml
done
echo "inbox:" >> conf/services.yml
for inbox_host in $INBOX_HOSTS; do
  echo "  - hostname: $inbox_host" >> conf/services.yml
  echo "    port: $INBOX_PORT" >> conf/services.yml
done
echo "microblog:" >> conf/services.yml
for microblog_host in $MICROBLOG_HOSTS; do
  echo "  - hostname: $microblog_host" >> conf/services.yml
  echo "    port: $MICROBLOG_PORT" >> conf/services.yml
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

if [ $1 = "apache" ]; then
  # Render apache2.conf.
  sed "s/{{PROCESSES}}/$APACHE_PROCESSES/g" templates/apache2.conf > conf/apache2.conf
  sed -i "s/{{THREADSPERPROCESS}}/$APACHE_THREADSPERPROCESS/g" conf/apache2.conf
  sed -i "s/{{PYTHONHOME}}/$APACHE_PYTHONHOME/g" conf/apache2.conf
  sed -i "s/{{PYTHONPATH}}/$APACHE_PYTHONPATH/g" conf/apache2.conf
  sed -i "s/{{WSGIDIRPATH}}/$APACHE_WSGIDIRPATH/g" \
      conf/apache2.conf
  sed -i "s/{{WSGIFILENAME}}/$APACHE_WSGIFILENAME/g" \
      conf/apache2.conf

  # Set Apache configuration.
  sudo cp conf/apache2.conf /etc/apache2/

  # Restart Apache.
  sudo service apache2 restart
else
  # Start flask server.
  export FLASK_APP=$WISE_HOME/microblog_bench/web/src/web.py
  flask run --port 5000 &
  echo "$!" > pid
fi

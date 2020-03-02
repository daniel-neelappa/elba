# If using bare metal hosts, set with your CloudLab username.
# If using virtual machines (appendix A of the tutorial), set with "ubuntu".
# If using Docker for containers, Container username should be "root", otherwise same as USERNAME
readonly USERNAME="neelappa"
readonly CONTAINER_USERNAME="root"
# If using bare metal hosts, set with "physical".
# If using virtual machines (appendix A of the tutorial), set with "vm".
readonly HOSTS_TYPE="physical"

#If using Docker Containers, set with "Docker"
readonly CONTAINER_TYPE="Docker"
# If using profile MicroblogBareMetalD430, set with "d430".
# If using profile MicroblogBareMetalC8220, set with "c8220".
readonly HARDWARE_TYPE="d430"

# Hostnames of each tier.
# Example (bare metal host): pc853.emulab.net
# Example (virtual machine): 10.254.3.128
readonly WEB_HOSTS="pc808.emulab.net"
readonly WEB_PORT=80
readonly POSTGRESQL_HOST="pc810.emulab.net"
readonly POSTGRESQL_PORT=5432
readonly WORKER_HOSTS="pc780.emulab.net"
readonly MICROBLOG_HOSTS="pc797.emulab.net"
readonly MICROBLOG_PORT=9090
readonly AUTH_HOSTS="pc817.emulab.net"
readonly AUTH_PORT=9091
readonly INBOX_HOSTS="pc798.emulab.net"
readonly INBOX_PORT=9092
readonly QUEUE_HOSTS="pc813.emulab.net"
readonly QUEUE_PORT=9093
readonly SUB_HOSTS="pc774.emulab.net"
readonly SUB_PORT=9094
readonly CLIENT_HOSTS="pc806.emulab.net"

#Container CPU Affinity
#Example: "1",2,3 ....
readonly WEB_CPU="1"
readonly POSTGRESQL_CPU="0"
readonly WORKER_CPU="2"
readonly MICROBLOG_CPU="3"
readonly AUTH_CPU="4"
readonly INBOX_CPU="5"
readonly QUEUE_CPU="6"
readonly SUB_CPU="7"
readonly CLIENT_CPU="7"


#Container SSH Port
#"22" is default, Use distinct ports if using Containers. Otherwise all "22"
readonly WEB_SSH="4978"
readonly POSTGRESQL_SSH="4972"
readonly WORKER_SSH="4973"
readonly MICROBLOG_SSH="4974"
readonly AUTH_SSH="4975"
readonly INBOX_SSH="4976"
readonly QUEUE_SSH="4977"
readonly SUB_SSH="4937"
readonly CLIENT_SSH="4979"

# Apache/mod_wsgi configuration.
readonly APACHE_PROCESSES=8
readonly APACHE_THREADSPERPROCESS=4

# Postgres configuration.
readonly POSTGRES_MAXCONNECTIONS=100

# Workers configuration.
readonly NUM_WORKERS=32

# Microservices configuration.
AUTH_THREADPOOLSIZE=32
INBOX_THREADPOOLSIZE=32
QUEUE_THREADPOOLSIZE=32
SUB_THREADPOOLSIZE=32
MICROBLOG_THREADPOOLSIZE=32

# Either 0 or 1.
readonly WISE_DEBUG=0

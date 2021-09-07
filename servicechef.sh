#!/bin/sh
MONGO=0
MONGOFILE=0
REDIS=0
REDISFILE=0
NODE=0
NODEMODULES=0
SYSTEMD=0
NUMA=0

NAME="$1"
PROJ_DIR=~/Services/$NAME
mkdir PROJ_DIR

for $arg in "$@"
do
    case $arg in
        -m|--mongo)
        MONGO=1
        shift
        ;;
        -m=*|--mongo=*)
        # takes in <file>.mongo see example
        MONGO=1
        MONGOFILE="${arg#*=}"
        shift
        ;;
        -r|--redis)
        REDIS=1
        shift
        ;;
        -r=*|--redis=*)
        REDIS=1
        REDISFILE="${arg#*=}"
        shift
        ;;
        -n|--node)
        NODE=1
        shift
        ;;
        -n=*|--node=*)
        # these are comma separated values representing the node modules to install
        # if express is one of them, build the files based around how I like to set up express routes
        NODE=1
        NODEMODULES=$(echo "${arg#*=}" | tr "," " ")
        shift
        ;;
        -d|--systemd)
        SYSTEMD=1
        shift
        ;;
        --numa)
        NUMA=1
        shift
        ;;
        *)
        shift
        ;;
    esac
done

if [ $MONGO ] # mongo 5.0 for ubuntu 18
then
    apt-get -y --force-yes install gnupg
    wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
    apt-get update
    apt-get install -y mongodb-org
    systemctl daemon-reload
    systemctl start mongod
    systemctl enable mongod
    
    if [ $NUMA ]
    then
        systmectl stop mongod
        systemctl disable mongod
        sudo apt-get install -y numactl
        cp mongodnuma.service /etc/systemd/system
        systemctl daemon-reload
        systemctl start mongodnuma
        systemctl enable mongodnuma 
    fi
fi 

if [ $MONGOFILE ]
then
    while read p; do
        echo "$p" #TODO parse mongofile
    done < $MONGOFILE
fi
cd PROJ_DIR

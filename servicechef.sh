#!/bin/sh
MONGO=0
MONGOFILE=0
REDIS=0
REDISFILE=0
NODE=0
NODEMODULES=0
SYSTEMD=0

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
        *)
        shift
        ;;
    esac
done

cd PROJ_DIR

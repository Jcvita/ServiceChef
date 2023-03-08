#!/bin/bash

source .env

MONGO=0
MONGOFILE=0
REDIS=0
REDISFILE=0
NODE=0
NODEMODULES=0
SYSTEMD=0
NUMA=0

CLUSTERS_DIR="clusters/"
INVENTORY_DIR="inventory/"

ACTION="$1"

# if the first arg is "create"
# if [ $ACTION = "create" ]
if [ "$ACTION" = "create" ]
then
    # for arg in every arg after the second one
    for arg in "${@:2}"
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
fi



installMongo() { # mongo 5.0 for ubuntu 18
    apt-get -y --force-yes install gnupg
    wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
    apt-get update
    apt-get install -y mongodb-org
    systemctl daemon-reload
    systemctl start mongod
    systemctl enable mongod
    
    if [ $1 ] # if any args, configure for numa (lxc containers)
    then
        systmectl stop mongod
        systemctl disable mongod
        sudo apt-get install -y numactl
        cp mongodnuma.service /etc/systemd/system
        systemctl daemon-reload
        systemctl start mongodnuma
        systemctl enable mongodnuma 
    fi

    if [ $2 ] # if second arg is passed, use the file to configure mongo
    then
        #if $2 is not a valid file, exit with bad file message
        if [ ! -f $2 ]
        then
            echo "Bad mongofile"
            exit 1
        fi

        while read p; do
            echo "$p" #TODO parse mongofile
        done < $2
    fi
}

installRedis() {
    apt-get install -y redis-server
    systemctl daemon-reload
    systemctl start redis-server
    systemctl enable redis-server

    if [ $1 ] # if any args, configure for numa (lxc containers)
    then
        systmectl stop redis-server
        systemctl disable redis-server
        sudo apt-get install -y numactl
        cp redisnuma.service /etc/systemd/system
        systemctl daemon-reload
        systemctl start redisnuma
        systemctl enable redisnuma 
    fi

    if [ $2 ] # if second arg is passed, use the file to configure redis
    then
        #if $2 is not a valid file, exit with bad file message
        if [ ! -f $2 ]
        then
            echo "Bad redisfile"
            exit 1
        fi

        while read p; do
            echo "$p" #TODO parse redisfile
        done < $2
    fi
} 

#ARGS: <cluster_name> <inventory_item>
createCluster() {
    CLUSTER_NAME=$1
    INVENTORY_ITEM=$2

    # if INVENTORY_DIR doesn't exist, create it
    if [ ! -d $INVENTORY_DIR ]
    then
        mkdir $INVENTORY_DIR
    fi

    # if INVENTORY_ITEM doesn't exist in the inventory directory, exit with error
    if [ ! -d $INVENTORY_DIR/$INVENTORY_ITEM ]
    then
        echo "Bad inventory item. Please create inventory item in $INVENTORY_DIR/$INVENTORY_ITEM"
        exit 1
    fi

    #get the first file in the directory subnets. chop the last 5 characters off
    SUBNET_FILE=$(ls $INVENTORY_DIR/$INVENTORY_ITEM/subnets | head -n 1 | cut -c 1-5)
    SUBNET="10.0.$SUBNET_FILE"

    cd $CLUSTERS_DIR
    mkdir $CLUSTER_NAME
    cd $CLUSTER_NAME


    # TODO take input to loop through templates, appending new create lxc container operations for each desired template
    CREATECLUSTERYAML="---
- name: Create LXC containers in separate subnets
  hosts: $INVENTORY_ITEM
  gather_facts: no
  vars_files:
    - ../../inventory/$INVENTORY_ITEM/templates.yaml
  vars:
    cluster_name: $CLUSTER_NAME
  tasks:
    - name: Create new Linux Bridge interface
      proxmox:
        api_user: {{ PROX_USER }}
        api_password: {{ PROX_PASS }}
        api_host: {{ PROX_HOST }}
        api_port: {{ PROX_PORT }}
        node: {{ PROX_NODE }}
        vmid: 0
        state: present
        type: bridge
        bridge: \"{{ cluster_name }}\"
      register: bridge_result

    - name: Create new LXC containers
      lxc_container:
        api_user: {{ PROX_USER }}
        api_password: {{ PROX_PASS }}
        api_host: {{ PROX_HOST }}
        api_port: {{ PROX_PORT }}
        name: \"{{ item }}\"
        state: started
        template: \"{{ item }}\"
        vmbr: \"{{ cluster_name }}\"
        interfaces:
          eth0:
            hwaddr: \"00:11:22:33:44:{{ loop.index }}\"
            ipv4: \"{{ subnet_start + loop.index }}/24\"
        netfilter: \"1\"
      loop: \"{{ container_templates }}\"
      when: bridge_result.changed == True

    - name: Create LXC containers
      include_role:
        name: create_container
      loop: \"{{ container_groups }}\"
"
}

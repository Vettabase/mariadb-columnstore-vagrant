#!/usr/bin/bash

PRIMARY_IP="${PRIMARY_IP:-192.168.50.11}"
CMAPI_FILE=".cmapi_key"

if [[ -e ${PWD}/config.sh ]]
then
    echo "Sourcing config.sh"
    source ${PWD}/config.sh
fi


_cmd() {
    node=$1
    shift
    vagrant ssh $node -c "$@"
}

restart_cmapi() {
    _cmd $1 "systemctl restart mariadb-columnstore-cmapi"
}

restart_mariadb() {
    _cmd $1 "system restart mariadb"
}

gen_key() {
    if [[ ! -e ${CMAPI_FILE} ]]
    then
        cmapi_key=$(openssl rand -hex 32)
        echo $cmapi_key > ${CMAPI_FILE}
    else
        echo "Key file already exists at ${CMAPI_FILE}"
        exit 1
    fi
}

get_key() {
    if [[ -e ${CMAPI_FILE} ]]
    then
        echo $(cat ${CMAPI_FILE})
        exit 0
    else
        echo "ERROR missing cmapi key file at ${CMAPI_FILE}"
        exit 1
    fi
}

set_key() {
    k=$(get_key)
    curl -k -s -X PUT https://${PRIMARY_IP}:8640/cmapi/0.4.0/cluster/node \
    --header "Content-Type:application/json" \
    --header "x-api-key:${k}" \
    --data "{\"timeout\":15, \"node\": \"${PRIMARY_IP}\"}" \
    | jq .
}

status() {
    k=$(get_key)
    if [[ -z $1 ]]
    then
        curl -k -s https://${PRIMARY_IP}:8640/cmapi/0.4.0/cluster/status \
        --header "Content-Type:application/json" \
        --header "x-api-key:${k}" \
        | jq .
    else
        curl -k -s https://${1}:8640/cmapi/0.4.0/cluster/status \
        --header "Content-Type:application/json" \
        --header "x-api-key:${k}" \
        | jq .
    fi
}

add() {
    if [[ -z $1 ]]
    then
        echo "Need an ip address"
        exit 1
    fi
    node="${1}"
    k=$(get_key)
    curl -k -s -X PUT https://${PRIMARY_IP}:8640/cmapi/0.4.0/cluster/node \
    --header "Content-Type:application/json" \
    --header "x-api-key:${k}" \
    --data "{\"timeout\":15, \"node\": \"${node}\"}" \
    | jq .
}


rm() {
    if [[ -z $1 ]]
    then
        echo "Need an ip address"
        exit 1
    fi
    node="${1}"
    k=$(get_key)
    curl -k -s -X DELETE https://${PRIMARY_IP}:8640/cmapi/0.4.0/cluster/node \
    --header "Content-Type:application/json" \
    --header "x-api-key:${k}" \
    --data "{\"timeout\":15, \"node\": \"${node}\"}" \
    | jq .
}

start() {
    if [[ -z $1 ]]
    then
        node=${PRIMARY_IP}
    else
        node="${1}"
    fi
    k=$(get_key)

    curl -s -X PUT https://${node}:8640/cmapi/0.4.0/cluster/start \
    --header "Content-Type:application/json" \
    --header "x-api-key:${k}" \
    --data "{\"timeout\":60}" -k | jq .
}

config() {
    if [[ -z $1 ]]
    then
        node=${PRIMARY_IP}
    else
        node="${1}"
    fi
    k=$(get_key)

    curl -s -X GET https://${node}:8640/cmapi/0.4.0/node/config \
    --header "Content-Type:application/json" \
    --header "x-api-key:${k}" \
    --data "{\"timeout\":60}" -k | jq .
}


shutdown() {
    if [[ -z $1 ]]
    then
        node=${PRIMARY_IP}
    else
        node="${1}"
    fi
    k=$(get_key)

    curl -s -X PUT https://${node}:8640/cmapi/0.4.0/cluster/shutdown \
    --header "Content-Type:application/json" \
    --header "x-api-key:${k}" \
    --data "{\"timeout\":60}" -k | jq .
}

mode_set() {
    if [[ -z $1 ]]
    then
        node=${PRIMARY_IP}
    else
        node="${1}"
    fi
    k=$(get_key)

    if [[ -z $2 ]]
    then
        echo "missing mode-set parameter"
        exit 1
    fi

    curl -s -X PUT https://${node}:8640/cmapi/0.4.0/cluster/mode-set\
    --header "Content-Type:application/json" \
    --header "x-api-key:${k}" \
    --data "{\"timeout\":15, \"mode\": \"${2}\"}" -k | jq .
}

cluster_up() {
    if [[ ! -z $1 ]]
    then
        export MDB_CLUSTER_SIZE=$1
    else
        export MDB_CLUSTER_SIZE=${MDB_CLUSTER_SIZE:-3}
    fi
    read -p "Cluster size is ${MDB_CLUSTER_SIZE}, continue?"
    vagrant up --no-provision && vagrant provision
}

cluster_destroy() {
    if [[ ! -z $1 ]]
    then
        export MDB_CLUSTER_SIZE=$1
    else
        export MDB_CLUSTER_SIZE=${MDB_CLUSTER_SIZE:-3}
    fi
    vagrant destroy -f
    if [[ -d columnstore ]]
    then
        rm -Rf columnstore
    fi
    for v in $(virsh list --all | grep mariadb-columnstore-vagrant | awk '{print $2}')
    do
        echo "Deleting VM defintion: ${v}"
        virsh undefine "${v}"
    done
    for v in $(virsh vol-list --pool default | grep mariadb-columnstore-vagrant | awk '{print $1}')
    do
        echo "Deleting volume image: ${v}"
        virsh vol-delete --pool default "${v}"
    done
}

_usage() {
    echo "Please specify a command"
    echo "cluster.sh [command]"
    IFS=$'\n'
    for f in $(declare -F)
    do
        echo "${f:11}" | grep -v ^_
    done

}

local_cmd="${1}"
shift
case $local_cmd in
    up)
        cluster_up "$@" ;;
    destroy)
        cluster_destroy ;;
    add)
        add "$@" ;;
    rw)
        mode_set "$1" "readwrite" ;;
    ro)
        mode_set "$1" "readonly" ;;
    rm)
        rm "$@" ;;
    config)
        config "$@" ;;
    start)
        start "$@" ;;
    shutdown)
        shutdown "$@" ;;
    stop)
        shutdown "$@" ;;
    status)
        status "$@" ;;
    set)
        set_key ;;
    get)
        get_key ;;
    gen)
        gen_key ;;
    ip)
        echo $PRIMARY_IP ;;
    restart-cmapi)
        restart_cmapi "$@" ;;
    restart-mariadb)
        restart_mariadb"$@" ;;
    *)
        _usage ;;
esac

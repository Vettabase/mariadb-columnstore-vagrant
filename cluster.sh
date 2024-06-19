#!/usr/bin/bash

PRIMARY_IP="${PRIMARY_IP:-192.168.50.11}"
CMAPI_FILE=".cmapi_key"


cmd() {
    node=$1
    shift
    vagrant ssh $node -c "$@"
}

restart_cmapi() {
    cmd $1 "systemctl restart mariadb-columnstore-cmapi"
}

restart_mariadb() {
    cmd $1 "system restart mariadb"
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

local_cmd="${1}"
shift
case $local_cmd in
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
        echo "unknown command" ;;
esac
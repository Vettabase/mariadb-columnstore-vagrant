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

print_key() {
    k=$(get_key)
    echo $k
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
    echo "Adding ${1}"
    k=$(get_key)
    curl -k -s -X PUT https://${PRIMARY_IP}:8640/cmapi/0.4.0/cluster/node \
    --header "Content-Type:application/json" \
    --header "x-api-key:${k}" \
    --data "{\"timeout\":15, \"node\": \"${1}\"}" \
    | jq .
}


local_cmd="${1}"
shift
case $local_cmd in
    add)
        add "$@" ;;
    status)
        status "$@" ;;
    set)
        set_key ;;
    get)
        print_key ;;
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
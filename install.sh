#!/usr/bin/env bash

##########################################
#                                        #
#             VETTABASE LTD              #
#      COLUMNSTORE DOCUMENTATION         #
# http://columnstore-docs.vettabase.com/ #
#                                        #
##########################################


if [[ -z $1 ]]
then
    NODE_NUMBER=1
elif [[ $1 == 'SINGLE' ]]
then
    NODE_NUMBER=1
else
    NODE_NUMBER=${1}
fi

if [[ $MDB_CLUSTER_SIZE -gt 1 ]]
then
    echo "##########################################"
    echo "INSTALLING NODE ${NODE_NUMBER}/${MDB_CLUSTER_SIZE}"
    echo "##########################################"
fi

export DEBIAN_FRONTEND=noninteractive
export CS_CACHE_SIZE="${CS_CACHE_SIZE:-2g}"
JOIN_USER="${JOIN_USER:-joiner}"
JOIN_PASS="${JOIN_PASS:-joiner123)}"
REPL_USER="${REPL_USER:-repl}"
REPL_PASS="${REPL_PASS:-repl123}"
REPL_GRANTS="REPLICA MONITOR,REPLICATION REPLICA,REPLICATION REPLICA ADMIN,REPLICATION MASTER ADMIN"
JEMALLOC_PATH="/usr/lib/x86_64-linux-gnu/libjemalloc.so.2"

mariadb_configure_columnstore() {
	mcsSetConfig CrossEngineSupport User ${JOIN_USER}
	mcsSetConfig CrossEngineSupport Password ${JOIN_PASS}
	mcsSetConfig CrossEngineSupport host "127.0.0.1"
    mariadb -e "CREATE USER IF NOT EXISTS '${JOIN_USER}'@'127.0.0.1' IDENTIFIED BY '${JOIN_PASS}'"
    mariadb -e "GRANT SELECT,PROCESS ON *.* TO '${JOIN_USER}'@'127.0.0.1'"
}

mariadb_configure_custom_sql() {
    VAGRANT_USER="GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'localhost' IDENTIFIED VIA unix_socket;"
    mariadb --show-warnings -NBe "${VAGRANT_USER}"
    mariadb --show-warnings -NBe "FLUSH PRIVILEGES;"

    CUSTOM_SQL="/vagrant/custom.sql"
    if [[ -e ${CUSTOM_SQL} ]]
    then
        echo "Loading custom SQL from ${CUSTOM_SQL}"
        mariadb < ${CUSTOM_SQL}
    fi
}

install_base() {
    apt-get update -yq
    apt-get install -yq \
        apt-transport-https \
        curl \
        pwgen \
        ca-certificates \
        gpg \
        tzdata \
        jq
}

preconfig () {
    sysctl vm.swappiness=$OS_SWAPPINESS
    echo $OS_SWAPPINESS > /proc/sys/vm/swappiness
    echo "vm.swappiness=$OS_SWAPPINESS" >> $( ls -1 /etc/sysctl.d/*.conf | tail -1 )

    # make scripts in utils/ easily available for later use
    echo 'PATH="${PATH}":/vagrant/utils' > /etc/profile.d/vagrant_profile.sh

    groupadd -r mysql && useradd -r -g mysql mysql --home-dir /var/lib/mysql
    systemctl disable apparmor
    ufw disable
    localedef -i en_US -f UTF-8 en_US.UTF-8
}

set_jemalloc() {
    /vagrant/utils/edini add /lib/systemd/system/mariadb.service Service -o "Environment=LD_PRELOAD=${JEMALLOC_PATH}"
}

install_mariadb() {
    REPO_URL="deb [signed-by=/etc/apt/keyrings/mariadb-keyring.pgp] https://deb.mariadb.org/${MDB_VERSION}/ubuntu ${OS_CODENAME} main"
    REPO_FILE="/etc/apt/sources.list.d/mariadb.list"
    KEY_FILE=/etc/apt/keyrings/mariadb-keyring.pgp
    mkdir -p /etc/apt-get/keyrings
    if [[ ! -f ${KEY_FILE} ]]
    then
        curl -o ${KEY_FILE} 'https://mariadb.org/mariadb_release_signing_key.pgp'
    fi
    if [[ ! -f ${REPO_FILE} ]]
    then
        echo ${REPO_URL} > ${REPO_FILE}
    fi
    apt-get update -yq
    apt-get install -yq \
        mariadb-server \
        mariadb-backup \
        mariadb-plugin-columnstore

    if  [[ $MDB_ALLOW_REMOTE_CONNECTIONS == 1 ]]
    then
        CS_CNF_BIND_ADDRESS="bind_address=0.0.0.0"
    else
        CS_CNF_BIND_ADDRESS="bind_address=127.0.0.1"
    fi

    if [[ -e /vagrant/custom.cnf ]]
    then
        cp /vagrant/custom.cnf /etc/mysql/mariadn.conf.d/custom.cnf
    fi

	CS_CNF="/etc/mysql/mariadb.conf.d/99_cs.cnf"
    echo "[mariadbd]" > $CS_CNF
    echo $CS_CNF_BIND_ADDRESS >> $CS_CNF
    echo "plugin_maturity=alpha" >> $CS_CNF
    echo "log_error=error.log" >> $CS_CNF
    echo "character_set_server= utf8" >> $CS_CNF
    echo "collation_server= utf8_general_ci" >> $CS_CNF
    echo "log_bin= mariadb-bin" >> $CS_CNF
    echo "log_bin_index= mariadb-bin.index" >> $CS_CNF
    echo "relay_log= mariadb-relay" >> $CS_CNF
    echo "relay_log_index= mariadb-relay.index" >> $CS_CNF
    echo "log_slave_updates= ON" >> $CS_CNF
    echo "gtid_strict_mode= ON" >> $CS_CNF
    echo "server_id=${NODE_NUMBER}" >> $CS_CNF

    systemctl enable mariadb
    set_jemalloc
    systemctl daemon-reload
    systemctl restart mariadb
    systemctl restart mariadb-columnstore

    . /vagrant/utils/timezones-load.sh


}

install_cmapi() {
# MDB_CLUSTER_SIZE = 'SINGLE' or 1, excludes CMAPI.
# In other cases:
#     - Install CMPAI
#     - Enable and restart both MariaDB and CMAPI services
#     - Enable CMAPI logs
#     - Restart CMAPI again to make config changes effective
    if [ $MDB_CLUSTER_SIZE -gt 1 ]; then
        mariadb -e "CREATE USER IF NOT EXISTS '${REPL_USER}'@'%' IDENTIFIED BY '${REPL_PASS}'"
        mariadb -e "GRANT ${REPL_GRANTS} ON *.* TO '${REPL_USER}'@'%'"

        systemctl stop mariadb
        systemctl stop mariadb-columnstore

        apt-get install -yq mariadb-columnstore-cmapi
        systemctl enable mariadb-columnstore-cmapi

        CMAPI_CONFIG_FILE=/etc/columnstore/cmapi_server.conf
        sed -i "s|^log.access_file.*|log.access_file = '/var/lib/columnstore/cs.access.log'|" $CMAPI_CONFIG_FILE
        sed -i "s|^log.error_file.*|log.error_file = '/var/lib/columnstore/cs.error.log'|" $CMAPI_CONFIG_FILE

        # previous changes require restart
        systemctl restart mariadb
        systemctl restart mariadb-columnstore-cmapi

        if [[ ${NODE_NUMBER} -gt 1 ]]
        then
            mariadb -e "STOP SLAVE"
            mariadb -e "CHANGE MASTER TO MASTER_HOST='${MDB_MASTER_HOST}',MASTER_USER='${REPL_USER}',MASTER_PASSWORD='${REPL_PASS}',MASTER_USE_GTID=slave_pos;"
            mariadb -e "START SLAVE"
            mariadb -e "SET GLOBAL read_only=ON"
        fi
    fi
}

mariadb_install_engines() {
    # MDB_EXTRA_ENGINES os a comma-separated list of engines to install.
    # We wrap it with additional commas to avoid confusion if an engine name
    # is contained in another, which currenlty is the case for FEDERATED/FEDERATEDX.
    if [[ $MDB_EXTRA_ENGINES == 'ALL' ]]; then
        MDB_EXTRA_ENGINES=',S3,CONNECT,MROONGA,OQGRAPH,SPIDER,ARCHIVE,BLACKHOLE,FEDERATEDX,'
    else
        MDB_EXTRA_ENGINES=$(echo $MDB_EXTRA_ENGINES | tr -d ' ')
        MDB_EXTRA_ENGINES=",$MDB_EXTRA_ENGINES,"
        MDB_EXTRA_ENGINES=$(echo "$MDB_EXTRA_ENGINES" | tr '[:lower:]' '[:upper:]')
    fi
    # plugins that are in the plugin_dir but not installed
    [[ $MDB_EXTRA_ENGINES == *",S3,"* ]]          && apt-get install -yq mariadb-plugin-s3
    [[ $MDB_EXTRA_ENGINES == *",CONNECT,"* ]]     && apt-get install -yq mariadb-plugin-connect
    [[ $MDB_EXTRA_ENGINES == *",MROONGA,"* ]]     && apt-get install -yq mariadb-plugin-mroonga
    [[ $MDB_EXTRA_ENGINES == *",OQGRAPH,"* ]]     && apt-get install -yq mariadb-plugin-oqgraph
    [[ $MDB_EXTRA_ENGINES == *",SPIDER,"* ]]      && apt-get install -yq mariadb-plugin-spider
    # plugins that need be installed from a separate package
    [[ $MDB_EXTRA_ENGINES == *",ARCHIVE,"* ]]     && mariadb -e "INSTALL SONAME 'ha_archive';"
    [[ $MDB_EXTRA_ENGINES == *",BLACKHOLE,"* ]]   && mariadb -e "INSTALL SONAME 'ha_blackhole';"
    [[ $MDB_EXTRA_ENGINES == *",FEDERATED,"* ]]   && mariadb -e "INSTALL SONAME 'ha_federated';"
    [[ $MDB_EXTRA_ENGINES == *",FEDERATEDX,"* ]]  && mariadb -e "INSTALL SONAME 'ha_federatedx';"
}


install_base
preconfig
install_mariadb
mariadb_configure_columnstore
mariadb_install_engines
install_cmapi
mariadb_configure_custom_sql


if [ $OS_INSTALL_MYCLI == 1 ]; then
    . /vagrant/utils/mycli-install.sh
fi


echo '<------------------------------->
<   MariaDB ColumnStore Image   >
<     by Vettabasse             >
<------------------------------->

MariaDB ColumnStore Unofficial Documentation Project:
http://columnstore-docs.vettabase.com

To obtain assistance or training from Vettabase:
https://vettabase.com
' > /etc/motd

#!/usr/bin/env bash

##########################################
#                                        #
#             VETTABASE LTD              #
#      COLUMNSTORE DOCUMENTATION         #
# http://columnstore-docs.vettabase.com/ #
#                                        #
##########################################


# Required S3 Variables
##USE_S3_STORAGE=1
##S3_BUCKET=data
##S3_ACCESS_KEY=
##S3_SECRET_KEY

# Required S3 Variables for AWS
##S3_REGION=us-east-1

# Required S3 Variables for S3 Compatible Storage
##S3_HOSTNAME
##S3_PORT

if [[ -z $1 ]]
then
    NODE_NUMBER=1
elif [[ $1 == 'SINGLE' ]]
then
    NODE_NUMBER=1
else
    NODE_NUMBER=${1}
fi

if [[ $MDB_CLUSTER_SIZE != 'SINGLE' ]]
then
    echo "##########################################"
    echo "INSTALLING NODE ${NODE_NUMBER}/${MDB_CLUSTER_SIZE}"
    echo "##########################################"
fi



export DEBIAN_FRONTEND=noninteractive
export CS_CACHE_SIZE="${CS_CACHE_SIZE:-2g}"

mariadb_configure_columnstore() {
	echo "Configuring Columnstore"
	#CS_CGROUP="${CS_CGROUP:-./}"
	#mcsSetConfig SystemConfig CGroup "${CS_CGROUP}"
	LANG_CNF=/etc/mysql/mariadb.conf.d/lang.cnf
	echo "[mariadbd]" > $LANG_CNF
	echo "collation_server=utf8_general_ci" >> $LANG_CNF
	echo "character_set_server=utf8" >> $LANG_CNF

	CROSSENGINEJOIN_USER="${CROSSENGINEJOIN_USER:-cross_engine_joiner}"
	CROSSENGINEJOIN_PASS="${CROSSENGINEJOIN_PASS:-$(pwgen --numerals --capitalize 32 1)}"

	mcsSetConfig CrossEngineSupport User ${CROSSENGINEJOIN_USER}
	mcsSetConfig CrossEngineSupport Password ${CROSSENGINEJOIN_PASS}
	mcsSetConfig CrossEngineSupport host "127.0.0.1"
}

mariadb_configure_s3() {
	if [[ -z ${USE_S3_STORAGE}  ]]; then
		echo "Missing USE_S3_STORAGE, Skipping S3 configuration"
		return
	fi

	echo "Configuring S3"

	declare -A S3_CNF
	S3_CNF["s3"]="ON"

	if [[ -n ${S3_BUCKET} ]]; then
		S3_CNF["s3_bucket"]=${S3_BUCKET}
	else
		echo "ERROR USE_S3_STORAGE is set but missing S3_BUCKET"
        exit 1
	fi

	if [[ -n ${S3_REGION} ]] && [[ -z ${S3_HOSTNAME} ]]; then
		S3_CNF["s3_region"]=${S3_REGION}
        S3_ENDPOINT="${S3_ENDPOINT:-s3.${S3_REGION}.amazonaws.com}"
    elif [[ -n {$S3_HOSNAME} ]]; then
        S3_CNF["s3_host_name"]=${S3_HOSTNAME}
        S3_ENDPOINT=${S3_HOSTNAME}
	else
		echo "ERROR USE_S3_STORAGE is set but missing S3_REGION"
        exit 1
	fi

	if [[ -n ${S3_ACCESS_KEY} ]]; then
		S3_CNF["s3_access_key"]=${S3_ACCESS_KEY}
	else
		echo "ERROR USE_S3_STORAGE is set but missing S3_ACCESS_KEY"
        exit 1
	fi

	if [[ -n ${S3_SECRET_KEY} ]]; then
		S3_CNF["s3_secret_key"]=${S3_SECRET_KEY}
	else
		echo "ERROR USE_S3_STORAGE is set but missing S3_SECRET_KEY"
        exit 1
	fi

	# Custom S3 Compatible host
	if [[ -n ${S3_PORT} ]]; then
		if [[ -z ${S3_HOSTNAME} ]]; then
			echo "ERROR S3_PORT configured but Missing S3_HOSTNAME"
            exit 1
		fi
		S3_CNF["s3_port"]=${S3_PORT}
		S3_CNF["s3_use_http"]="ON"
	fi

	# Storage Manager endpoint URL and port
	if [[ -n ${S3_PORT} ]]; then
		S3_ENDPOINT_PORT="port_number = ${S3_PORT}"
    else
        S3_ENDPOINT_PORT=""
	fi

	S3_CONFIG_PATH="/etc/mysql/mariadb.conf.d/s3.cnf"
	#sed -i "s|^#plugin-maturity.*|plugin-maturity = alpha" $S3_CONFIG_PATH

    echo "[mariadbd]" > $S3_CONFIG_PATH
    echo "plugin-maturity = alpha" >> $S3_CONFIG_PATH
	echo "plugin_load_add = ha_s3" >> $S3_CONFIG_PATH

	for section in "mariadb" "aria_s3_copy"; do
		echo "[${section}]" >> $S3_CONFIG_PATH
		for	S3_VAR in ${!S3_CNF[@]}; do
			echo "Setting ${S3_VAR}=${S3_CNF[$S3_VAR]} in section ${section}"
			echo "${S3_VAR}=${S3_CNF[$S3_VAR]}" >> $S3_CONFIG_PATH
		done
		echo "" >> $S3_CONFIG_PATH
	done

    cat $S3_CONFIG_PATH

    echo "Configuring StorageManager to use S3"
    mcsSetConfig Installation DBRootStorageType "StorageManager"
    mcsSetConfig StorageManager Enabled "Y"
    mcsSetConfig SystemConfig DataFilePlugin "libcloudio.so"
    sed -i "s|^service = LocalStorage|service = S3|" /etc/columnstore/storagemanager.cnf
    if [[ ! -z ${CS_CACHE_SIZE} ]]; then
        sed -i "s|cache_size =.*|cache_size = ${CS_CACHE_SIZE}|" /etc/columnstore/storagemanager.cnf
    fi
    if [[ -n ${S3_REGION} ]]; then
        sed -i "s|^region =.*|region = ${S3_REGION}|" /etc/columnstore/storagemanager.cnf
    fi
    sed -i "s|^bucket =.*|bucket = ${S3_BUCKET}|" /etc/columnstore/storagemanager.cnf
    sed -i "s|^# endpoint =.*|endpoint = ${S3_ENDPOINT}\n${S3_ENDPOINT_PORT}|" /etc/columnstore/storagemanager.cnf
    sed -i "s|^# aws_access_key_id =.*|aws_access_key_id = ${S3_ACCESS_KEY}|" /etc/columnstore/storagemanager.cnf
    sed -i "s|^# aws_secret_access_key =.*|aws_secret_access_key = ${S3_SECRET_KEY}|" /etc/columnstore/storagemanager.cnf
    if ! /usr/bin/testS3Connection >/var/log/mariadb/columnstore/testS3Connection.log 2>&1; then
        echo ""
        egrep -n '^service|^region|^bucket|^endpoint|^aws_*|^port_number' /etc/columnstore/storagemanager.cnf
        echo ""
        cat /var/log/mariadb/columnstore/testS3Connection.log 
		echo "Error: S3 Connectivity Failed"
        exit 1
    fi
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
        mariadb-plugin-columnstore \
        mariadb-plugin-s3

    if  [[ $MDB_ALLOW_REMOTE_CONNECTIONS == 1 ]]
    then
        CS_CNF_BIND_ADDRESS="bind_address=0.0.0.0"
    else
        CS_CNF_BIND_ADDRESS="bind_address=127.0.0.1"
    fi

	CS_CNF="/etc/mysql/mariadb.conf.d/99_cs.cnf"
    echo "[mariadbd]" > $CS_CNF
    echo $CS_CNF_BIND_ADDRESS >> $CS_CNF
    echo "log_error=mariadbd.err" >> $CS_CNF
    echo "character_set_server= utf8" >> $CS_CNF
    echo "collation_server= utf8_general_ci" >> $CS_CNF
    echo "log_bin= mariadb-bin" >> $CS_CNF
    echo "log_bin_index= mariadb-bin.index" >> $CS_CNF
    echo "relay_log= mariadb-relay" >> $CS_CNF
    echo "relay_log_index= mariadb-relay.index" >> $CS_CNF
    echo "log_slave_updates= ON" >> $CS_CNF
    echo "gtid_strict_mode= ON" >> $CS_CNF
    echo "server_id=${NODE_NUMBER}" >> $CS_CNF

    systemctl restart mariadb
    systemctl restart mariadb-columnstore
    
    . /vagrant/utils/timezones-load.sh

}

install_cmapi() {
# MDB_CLUSTER_SIZE = 1 excludes CMAPI.
# In other cases:
#     - Install CMPAI
#     - Enable and restart both MariaDB and CMAPI services
#     - Enable CMAPI logs
#     - Generate a CMAPI key if needed
#     - Restart CMAPI again to make config changes effective
    if [ $MDB_CLUSTER_SIZE -gt 1 ]; then
        systemctl stop mariadb
        systemctl stop mariadb-columnstore
        apt-get install -yq mariadb-columnstore-cmapi
        
        systemctl enable mariadb
        systemctl enable mariadb-columnstore-cmapi
        systemctl restart mariadb
        systemctl restart mariadb-columnstore-cmapi

        CMAPI_CONFIG_FILE=/etc/columnstore/cmapi_server.conf
        sed -i "s|^log.access_file.*|log.access_file = '/var/lib/columnstore/cs.access.log'|" $CMAPI_CONFIG_FILE
        sed -i "s|^log.error_file.*|log.error_file = '/var/lib/columnstore/cs.error.log'|" $CMAPI_CONFIG_FILE
        if [ -z "$MDB_CMAPI_KEY" ]; then
            MDB_CMAPI_KEY=$( openssl rand -hex 32 )
        fi
        mcs cluster set api-key --key "$MDB_CMAPI_KEY"

        # previous changes require restart
        systemctl restart mariadb-columnstore-cmapi
    fi
}

mariadb_install_engines() {
    # MDB_EXTRA_ENGINES os a comma-separated list of engines to install.
    # We wrap it with additional commas to avoid confusion if an engine name
    # is contained in another, which currenlty is the case for FEDERATED/FEDERATEDX.
    if [[ $MDB_EXTRA_ENGINES == 'ALL' ]]; then
        MDB_EXTRA_ENGINES=',CONNECT,MROONGA,OQGRAPH,SPIDER,ARCHIVE,BLACKHOLE,FEDERATEDX,'
    else
        MDB_EXTRA_ENGINES=$(echo $MDB_EXTRA_ENGINES | tr -d ' ')
        MDB_EXTRA_ENGINES=",$MDB_EXTRA_ENGINES,"
        MDB_EXTRA_ENGINES=$(echo "$MDB_EXTRA_ENGINES" | tr '[:lower:]' '[:upper:]')
    fi
    # plugins that are in the plugin_dir but not installed
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
mariadb_install_engines
#install_cmapi
#mariadb_configure_columnstore
#mariadb_configure_s3
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

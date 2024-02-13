#!/usr/bin/env bash

# Populate timezone tables and restart MariaDB


echo 'Loading timezone information into MariaDB system tables'
mariadb-tzinfo-to-sql /usr/share/zoneinfo | mariadb -D mysql

# if the command failed, exit
ret=$?
if [[ "$ret" != '0' ]]; then
    echo "mariadb-tzinfo-to-sql failed with exit code: $ret"
    exit $ret
fi

# restart is required for the new timezone info to take effect
if [ "$SKIP_RESTART" == 1 ]; then
    echo 'Skippinng restart'
    echo 'Timezone changes might not take effect until restart'
else
    echo 'Restarting MariaDB'
    sudo systemctl restart mariadb
fi

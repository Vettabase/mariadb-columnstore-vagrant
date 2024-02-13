#!/usr/bin/env bash

if [[ -z "$1" ]] || [[ "$1" == 'help' ]]; then
    echo 'This is a wrapper for the vagrant command.

First it runs config.sh, so that the configuration becomes available to
the Vagrantfile via environment variables.
If confis.sh does not exist, create it from the template and edit it:

cp config.sh.template config.sh
editor config.sh

If you dont create this file, it will be created the first time you invoke
the script with default values.

Then the vagrant command is called. You can specify with commands to call
and its arguments (up to five), for example:

vagrant.sh destroy --force

If the action you pass is UP (uppercase), the script will ignore arguments
and run:

vagrant destroy --force
vagrant up

There are cases when using this script seems unnecessary, but it is not.
For example, if you change the BOX value in the configuration and you
create a VM using this script, you will not be able to destroy it by
calling "vagrant destroy" directly.
The non-obvious reason is that "vagrant destroy" reads the Vagrantfile.
'
    exit 0
fi

if [[ ! -f 'config.sh' ]]; then
    echo 'config.sh not found. Creating it from config.sh.template'
    cp config.sh.template config.sh
fi

./config.sh

action=$1

if [[ $action == 'UP' ]]; then
    vagrant destroy --force
    vagrant up
    ret=$?
else
    vagrant $action $2 $3 $4 $5 $6
    ret=$?
fi

exit $ret

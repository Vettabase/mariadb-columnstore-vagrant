#!/usr/bin/env bash

vagrant destroy -f && rm -Rf .vagrant
rm -Rf columnstore
for v in $(virsh list --all | grep mariadb-columnstore-vagrant | awk '{print $2}')
do
    virsh undefine $v
done

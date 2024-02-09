# MariaDB Columnstore Vagrant

A Vagrant installation with simple provisioning of MariaDB Columnstore, maintained by Vettabase.

## Requirements

* Vagrant
* [libvirt](https://vagrant-libvirt.github.io/vagrant-libvirt/) plugin

## Usage

### Single Node

Install and start the server, then login directory to the MariaDB shell:

    vagrant up
    vagrant ssh -c mariadb

Optionally load some sample data:

    vagrant ssh -c /vagrant/sample/load.sh

## TODO

* Multi-node setup
* Include an S3 target like Minio

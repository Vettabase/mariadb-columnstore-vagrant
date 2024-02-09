# MariaDB Columnstore Vagrant

A Vagrant installation with simple provision of MariaDB Columnstore, maintained by Vettabase.


## Requirements

* Vagrant
* [libvirt](https://vagrant-libvirt.github.io/vagrant-libvirt/) plugin

## Usage

### Single Node

Install and start the server, then login directory to the MariaDB shell. Optionally load some data into a Columnstore Engine table.

    vagrant up
    vagrant ssh -- mariadb
    MariaDB > source /vagrant/sample.sql

## TODO
* Multi-node
* Include an S3 target like Minio

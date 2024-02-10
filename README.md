# MariaDB Columnstore Vagrant

A Vagrant installation with simple provisioning of MariaDB Columnstore, maintained by Vettabase.

## Requirements

This Vagrantfile is tested with these providers:
  * [libvirt](https://vagrant-libvirt.github.io/vagrant-libvirt/)
  * [VirtualBox](https://developer.hashicorp.com/vagrant/docs/providers/virtualbox)

To install the libvirt plugin:

    sudo apt install qemu-kvm
    vagrant plugin install vagrant-libvirt

## Usage

### Single Node Setup

Install and start the server:

    vagrant up

To use a non-default provider:

    vagrant up --provider=virtualbox

Optionally load some sample data:

    vagrant ssh -c /vagrant/sample/load.sh

### Using a MariaDB ColumnStore VM

To log into the system:

    vagrant ssh

To connect to MariaDB:

    vagrant ssh -c mariadb

To run a query non-interactively:

    vagrant ssh -c mariadb -e "SELECT VERSION();"

## TODO

* Multi-node setup
* Include an S3 target like Minio

## Copyright and License

Copyright © Vettabase 2024

This Vagrantfile is distributed under the terms of the GPL, version 3.

If you haven't received a copy of the license, please find it here:
https://www.gnu.org/licenses/gpl-3.0.txt

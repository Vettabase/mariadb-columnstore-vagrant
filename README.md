# MariaDB Columnstore Vagrant

A Vagrant installation with simple provisioning of MariaDB Columnstore, maintained by Vettabase.

This Vagrantfile is used with default options to produce the `vettabase/mariadb-columnstore`
image:

https://app.vagrantup.com/vettabase/boxes/mariadb-columnstore

## About MariaDB ColumnStore

Technically, ColumnStore is a storage engine for MariaDB.

In practice it's much more than that, turning MariaDB into a clustered
data sharding solution for analytical workloads.

You can use it alongside with any other MariaDB feature: any SQL query,
other storage engines, Galera cluster, and so on.

For MariaDB, refer to the MariaDB KnowledgeBase:

https://mariadb.com/kb/

ColumnStore documentation was taken away from the MariaDB KB,
and replaced with incomplete, non-free documentation that is part
of MariaDB Enterprise documentation.

To bring back free documentation for the community, Vettabase started
the MariaDB ColumnStore Unofficial Documentation Project:

http://columnstore-docs.vettabase.com/

### About This Vagrantfile

We decided to build this Vagrantfile because the official MariaDB
ColumnStore Vagrant image was discontinued and completely removed
(see [MCOL-3906](https://jira.mariadb.org/browse/MCOL-3906)).

### Docker Images for MariaDB ColumnStore

At the time of this writing, official MariaDB ColumnStore Docker images
are based on MariaDB Enterprise and quite outdated (see this
[bug report](https://jira.mariadb.org/browse/MCOL-5646)).

For this reason, Vettabase decided to develop and maintain its own Docker
image:

https://hub.docker.com/r/vettadock/mariadb-columnstore

**NOTE: At the time of this writing, our Dockerfile is not production ready.
When it is, a `latest` tag will exist.**

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

### Operations

To operate the MariaDB service, use the regular [systemd](https://www.freedesktop.org/wiki/Software/systemd/)
commands.

To update the timezone system tables:

    vagrant ssh
    /vagrant/utils/timezones-load.sh

This will restart MariaDB. To avoid a restart, set `SKIP_RESTART=1`.

## TODO

* Multi-node setup
* Include an S3 target like Minio

## Maintainers and Credits

This is a [Vettabase](https://vettabase.com) project.

This Vagrantfile was originally developed and is currently maintained
by Richard Bensley <richard.bensley@vettabase.com>.

Anyone who makes a relevant contribution to this project will be
kudoed here, unless they ask not to be mentioned.

## Copyright and License

Copyright © Vettabase 2024

This peoject is distributed under the terms of the GPL, version 3.

If you haven't received a copy of the license, please find it here:
https://www.gnu.org/licenses/gpl-3.0.txt

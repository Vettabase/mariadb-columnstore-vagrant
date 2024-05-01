# MariaDB Columnstore Vagrant

A Vagrant installation with simple provisioning of MariaDB Columnstore, maintained by Vettabase.

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

### Configuration

Using this Vagrantfile rather than Vagrant Cloud allows to change its configuration
before creating a VM. The configuration is entirely contained in `config.sh`.
If this file doesn't exist, it can be created by copying `config.sh.template`.
If you don't do this, the file will be created when you run `vagrant up`.

The variables are the following.

`BOX`

The name of the box to be used as a base box.
It could be a base box tailored for your use case, or it could be a different
operating system. In this casem you should also change `OS_CODENAME`.

Default: `generic/ubuntu2204`

`MDB_VERSION`

MariaDB version. It should include the major and minor version, eg: 11.3.
Can be any version included in the official repositories.

Default: `11.3`

`MDB_ALLOW_REMOTE_CONNECTIONS`

Set exactly to `1` to allow non-local connections. This means that the
`bind_address` variable will be set to `0.0.0.0` rather than the default
`127.0.0.1`.

Default: `1`

`OS_CODENAME`

Codename of the Linux distribution as it is used by the repositories.
For example, for Ubuntu 22.04, it should be `jammy`.

Default: `jammy`

`OS_SWAPPINESS`

The value of Linux kernel parameter `os.swappiness`.

Default: `1`

`OS_INSTALL_MYCLI`

Set exactly to 1 to install the [mycli](https://www.mycli.net/) TUI.
Whatever the choice, the VM will include scripts to install, upgrade
or uninstall mycli later.

Default: `1`

`MDB_EXTRA_ENGINES`

Additional storage engines that should be installed.
It's a comma-separated, case-insensitive list. Spaces are ignored.

Default: `CONNECT,SPIDER,BLACKHOLE`

### Using a MariaDB ColumnStore VM

To log into the system:

    vagrant ssh

To connect to MariaDB:

    vagrant ssh -c mariadb

To run a query non-interactively:

    vagrant ssh -c mariadb -e "SELECT VERSION();"

### mycli

MariaDB official CLI client (`mariadb`) is always installed.

By default, mycli is also installed. If you don't want to install it,
set `OS_INSTALL_MYCLI` to any value other than 1.

The following scripts allow to install, upgrade or uninstall mycli later:

* `mysqli-install.sh`
* `mycli-upgrade.sh`
* `mycli-uninstall.sh`

They are in the `$PATH` and the default user can run them without `sudo`.

To use mycli interactively:

```
mycli
```

To run a query non-interactively:

```
mycli -e "SELECT VERSION()"
```

mycli official website:

https://www.mycli.net/

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

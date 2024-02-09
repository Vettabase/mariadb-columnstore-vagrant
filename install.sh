#!/usr/bin/env bash


# Config
source /vagrant/config.sh

# Repo
MARIADB_INSTALL_VERSION=${MARIADB_INSTALL_VERSION:-}
MARIADB_REPO_VERSION=${MARIABD_REPO_VERSION:-10.11.6}
DISTRO_VERSION=${DISTRO_VERSION:-jammy}

REPO_URL="deb http://archive.mariadb.org/mariadb-${MARIADB_REPO_VERSOIN}/repo/ubuntu/ ${DISTRO_VERSION} main main/debug"
REPO_FILE="/etc/apt/sources.list.d/mariadb.list"

sudo echo ${REPO_URL} > ${REPO_FILE}


# Update and install
sudo apt update -yq
sudo apt upgrade -yq
sudo apt install -yq \
    pwgen \
    ca-certificates \
    gpg \
    tzdata

sudo apt install -yq \
    mariadb-server="$MARIADB_VERSION" \
    mariadb-backup \
    mariadb-plugin-columnstore \
    mariadb-plugin-s3

# Run config
mariadb_configure_columnstore
mariadb_configure_s3
mariadb_configure_custom_sql


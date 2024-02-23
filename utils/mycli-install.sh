#!/usr/bin/env bash

# Install mycli CLI from pip

echo 'Installing pip3 if not present'
export DEBIAN_FRONTEND=noninteractive
sudo --preserve-env=DEBIAN_FRONTEND apt install -y python3-pip

echo 'Installing mycli from pip3'
sudo pip3 install --no-input mycli

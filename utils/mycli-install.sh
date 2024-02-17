#!/usr/bin/env bash

# Install mycli CLI from pip

echo 'Installing pip3 if not present'
DEBIAN_FRONTEND=noninteractive apt install -y python3-pip

echo 'Installing mycli from pip3'
pip3 install --no-input mycli

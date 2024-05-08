#!/usr/bin/env bash

echo "Installing dictoinary words..." && \
    sudo apt install -yq wbritish-huge && \
    echo "Loading words into sample.words..." && \
    sudo mariadb --show-warnings < /vagrant/sample/sample.sql && \
    mariadb --show-warnings -A -e "SELECT COUNT(*) FROM sample.words" && \
    echo "...Done"

#!/usr/bin/env bash

grep --color=never -oP "x-api-key\s*=\s*'\K[^<]+(?=')" /etc/columnstore/cmapi_server.conf

#!/usr/bin/env bash
set -euxo pipefail

sudo mkdir -p /run/postgresql
sudo chown "$(id -u):$(id -g)" /run/postgresql
pg_ctl -l "$PGDATA/server.log" start

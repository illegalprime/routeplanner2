#!/usr/bin/env bash
set -euxo pipefail

if [[ ! -d db ]]; then
  initdb -D db
  CREATE_ROLE=1
fi
sudo mkdir -p /run/postgresql
sudo chown "$(id -u):$(id -g)" /run/postgresql
pg_ctl -l "$PGDATA/server.log" "$1"
if [[ ${CREATE_ROLE:-} ]]; then
  createuser -s postgres
fi


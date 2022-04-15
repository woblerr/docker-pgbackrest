#!/usr/bin/env bash

# Exit on errors and on command pipe failures.
set -e

PG_CLUSTER="main"
PG_BIN="/usr/lib/postgresql/13/bin"
PG_DATA="/var/lib/postgresql/13/${PG_CLUSTER}"

# Start postgres.
pg_ctlcluster 13 ${PG_CLUSTER} start --foreground

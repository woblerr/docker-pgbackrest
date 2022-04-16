#!/usr/bin/env bash

# Exit on errors and on command pipe failures.
set -e

# PG_VERSION is set in the container's environment variables.
PG_CLUSTER="main"
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"
PG_DATA="/var/lib/postgresql/${PG_VERSION}/${PG_CLUSTER}"

# Start postgres.
pg_ctlcluster ${PG_VERSION} ${PG_CLUSTER} start --foreground

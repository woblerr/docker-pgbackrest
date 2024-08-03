#!/usr/bin/env bash

# Exit on errors and on command pipe failures.
set -e

# PG_VERSION is set in the container's environment variables.
PG_CLUSTER="main"
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"
PG_DATA="/var/lib/postgresql/${PG_VERSION}/${PG_CLUSTER}"
# Start sshd.
/usr/sbin/sshd -f ~/sshd/sshd_config

# Add host to known_hosts.
# Necessary for pgBackRest to work correctly over sftp.
ssh-keyscan -t rsa -p 2222 sftp-rsa > ~/.ssh/known_hosts
ssh-keyscan -t ed25519 -p 2222 sftp-ed25519 >> ~/.ssh/known_hosts

# Start postgres.
pg_ctlcluster ${PG_VERSION} ${PG_CLUSTER} start --foreground

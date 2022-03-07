#!/usr/bin/env bash

# Exit on errors and on command pipe failures.
set -e

# Add pg host to known_hosts.
# Necessary for pgBackRest to work correctly over ssh.
ssh-keyscan -t rsa -p 2222 pg > ~/.ssh/known_hosts

# Run pgBackRest test commands.
pgbackrest stanza-create --stanza demo
pgbackrest backup --stanza demo --type full

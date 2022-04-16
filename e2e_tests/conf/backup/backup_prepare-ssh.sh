#!/usr/bin/env bash

# Exit on errors and on command pipe failures.
set -e

# Add pg host to known_hosts.
# Necessary for pgBackRest to work correctly over ssh.
ssh-keyscan -t rsa -p 2222 pg-ssh > ~/.ssh/known_hosts

# Run pgBackRest test commands.
pgbackrest stanza-create --stanza demo
pgbackrest backup --stanza demo --type full

# Get results.
data_repo=$(pgbackrest info --stanza demo)
cnt_full_repo=$(echo "${data_repo}" | grep 'full backup' | wc -l)

# Passed results.
# 1 or 2 full backups.
# In this script only 1 full backup is created,
# but in the general pipeline (during makefile),
# this script is launched in two services (backup-ssh and baclup_alpine-ssh),
# so valid result is 1 or 2 value (for separate and together launch).
if [ "${cnt_full_repo}" -eq "1" ] || [ "${cnt_full_repo}" -eq "2" ]
then
    echo "[INFO] all tests passed"
    exit 0
else
    echo "[ERROR] some tests failed"
    echo "[ERROR] full backup in repo: ${cnt_full_repo}, valid values: 1 or 2"
    echo "${data_repo}"
    exit 1
fi

#!/usr/bin/env bash

# Exit on errors and on command pipe failures.
set -e

# Add hosts to known_hosts.
# Necessary for pgBackRest to work correctly over sftp.
ssh-keyscan -t rsa -p 2222 sftp >> ~/.ssh/known_hosts

# Run pgBackRest test commands.
pgbackrest stanza-create --stanza demo
pgbackrest backup --stanza demo --type full --repo 1
pgbackrest backup --stanza demo --type full --repo 2
pgbackrest backup --stanza demo --type diff --repo 2
pgbackrest backup --stanza demo --type full --repo 3

# Get results.
data_repo_1=$(pgbackrest info --stanza demo --repo 1)
data_repo_2=$(pgbackrest info --stanza demo --repo 2)
data_repo_3=$(pgbackrest info --stanza demo --repo 3)
cnt_full_repo_1=$(echo "${data_repo_1}" | grep 'full backup' | wc -l)
cnt_full_repo_2=$(echo "${data_repo_2}" | grep 'full backup' | wc -l)
cnt_diff_repo_2=$(echo "${data_repo_2}" | grep 'diff backup' | wc -l)
cnt_full_repo_3=$(echo "${data_repo_3}" | grep 'full backup' | wc -l)

# Passed results.
# For repo 1 (minio): 1 or 2 full backups.
# For repo 2 (tls server): 1 or 2 full backups and 1 diff backup.
# For repo 3 (sftp): 1 or 2 full backups.
# In this script only 1 full backup is created,
# but in the general pipeline (during makefile),
# this script is launched in two services (backup-tls and baclup_alpine-tls),
# so valid result is 1 or 2 value (for separate and together launch).
# The diff backup will always be 1 (by this script),
# since full are considered differential for the purpose of retention.
# See https://github.com/pgbackrest/pgbackrest/blob/e699402f99f70819bd922eb6150fbe1b837eca0d/src/command/expire/expire.c#L192-L194
if ([ "${cnt_full_repo_1}" -eq "1" ] || [ "${cnt_full_repo_1}" -eq "2" ]) && \
   ([ "${cnt_full_repo_2}" -eq "1" ] || [ "${cnt_full_repo_2}" -eq "2" ]) && \
   [ "${cnt_diff_repo_2}" -eq "1" ] && \
   ([ "${cnt_full_repo_3}" -eq "1" ] || [ "${cnt_full_repo_3}" -eq "2" ])
then
    echo "[INFO] all tests passed"
    exit 0
else
    echo "[ERROR] some tests failed"
    echo "[ERROR] full backup in repo 1: ${cnt_full_repo_1}, valid values: 1 or 2"
    echo "${data_repo_1}"
    echo "[ERROR] full backup in repo 2: ${cnt_full_repo_2}, valid values: 1 or 2"
    echo "[ERROR] diff backup in repo 2: ${cnt_diff_repo_2}, valid value: 1"
    echo "${data_repo_2}"
    echo "[ERROR] full backup in repo 3: ${cnt_full_repo_3}, valid values: 1 or 2"
    echo "${data_repo_3}"
    exit 1
fi

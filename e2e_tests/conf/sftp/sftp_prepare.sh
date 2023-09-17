#!/usr/bin/env bash

# Exit on errors and on command pipe failures.
set -e

# Start sshd.
/usr/sbin/sshd -f ~/sshd/sshd_config -D

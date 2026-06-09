#!/bin/bash
set -e
/usr/sbin/sshd
( while [ ! -S /var/run/docker.sock ]; do sleep 0.5; done; chmod 666 /var/run/docker.sock ) &
exec dockerd-entrypoint.sh "$@"

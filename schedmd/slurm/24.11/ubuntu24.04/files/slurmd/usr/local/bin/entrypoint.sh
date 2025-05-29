#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (C) SchedMD LLC.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

mkdir -p /run/slurm/
mkdir -p /run/sshd/
chmod 0755 /run/sshd/
mkdir -p /run/dbus/
rm -f /var/run/dbus/pid

export SLURMD_OPTIONS="${SLURMD_OPTIONS:-} $*"
export SSHD_OPTIONS="${SSHD_OPTIONS:-""}"
export SSSD_OPTIONS="${SSSD_OPTIONS:-""}"
export DBUS_OPTIONS="${DBUS_OPTIONS:-""}"

exec supervisord -c /etc/supervisor/supervisord.conf

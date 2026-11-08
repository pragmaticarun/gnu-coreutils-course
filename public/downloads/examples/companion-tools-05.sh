#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (companion-tools).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
dpkg -S /usr/bin/hostname
dpkg -S /usr/bin/kill
dpkg -S /usr/bin/uptime
set +e
command -v rsync >/dev/null
/usr/bin/printf 'rsync_status:%s\n' $?
command -v perf >/dev/null
/usr/bin/printf 'perf_status:%s\n' $?
command -v /usr/bin/time >/dev/null
/usr/bin/printf 'gnu_time_status:%s\n' $?
set -e

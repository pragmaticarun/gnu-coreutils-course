#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (companion-boundary).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
dpkg -S /usr/bin/grep
dpkg -S /usr/bin/sed
dpkg -S /usr/bin/mawk
dpkg -S /usr/bin/gawk
dpkg -S /usr/bin/tar
dpkg -S /usr/bin/vmstat
dpkg -S /usr/bin/iostat
dpkg -S /usr/bin/flock
dpkg -S /usr/bin/script
dpkg -S /usr/bin/column

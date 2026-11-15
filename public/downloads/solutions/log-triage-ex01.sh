#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (log-triage).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf '%s\n' 'OK' 'ERROR disk full' 'ERROR disk full' > build.log
LC_ALL=C /usr/bin/grep -F ERROR build.log | /usr/bin/sed 's/^ERROR //' | /usr/bin/awk '{c[$0]++} END {print c[$0], $0}' | LC_ALL=C /usr/bin/sort

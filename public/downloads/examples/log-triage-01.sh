#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (log-triage).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf '%s\n' 'INFO start' 'ERROR linker missing libfoo' 'ERROR linker missing libfoo' 'ERROR parser unexpected token' > build.log
LC_ALL=C /usr/bin/grep -F ERROR build.log | /usr/bin/sed 's/^ERROR //' > errors.txt
/usr/bin/awk '{c[$0]++} END {for (k in c) print c[k], k}' errors.txt | LC_ALL=C /usr/bin/sort

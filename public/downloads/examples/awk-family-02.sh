#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (awk-family).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'b\na\nb\n' > log
/usr/bin/awk '{c[$0]++} END {for (k in c) print c[k], k}' log | LC_ALL=C /usr/bin/sort
LC_ALL=C /usr/bin/sort log | /usr/bin/uniq -c | /usr/bin/sed 's/^ *//'

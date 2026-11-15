#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (large-duplicate-files).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/mkdir tree
/usr/bin/printf 'small\n' > tree/small.txt
/usr/bin/truncate -s 1M tree/hole
/usr/bin/find tree -type f -printf '%s %p\n' | LC_ALL=C /usr/bin/sort -n
/usr/bin/du -B1 tree/hole | /usr/bin/awk '{print "allocated:" $1}'

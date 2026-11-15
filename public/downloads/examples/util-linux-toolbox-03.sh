#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (util-linux-toolbox).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/fallocate -l 8192 blob
/usr/bin/du -B1 blob | /usr/bin/awk '{print "before:" $1}'
/usr/bin/fallocate --punch-hole --offset 0 --length 8192 blob
/usr/bin/du -B1 blob | /usr/bin/awk '{print "after:" $1}'
/usr/bin/stat -c 'apparent:%s' blob
/usr/bin/findmnt -n -o FSTYPE /
/usr/bin/lsblk -d -n -o TYPE | /usr/bin/sort -u

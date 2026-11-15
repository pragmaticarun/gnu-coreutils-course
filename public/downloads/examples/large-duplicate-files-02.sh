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
/usr/bin/printf 'same\n' > tree/a.bin
/usr/bin/printf 'same\n' > tree/b.bin
/usr/bin/find tree -type f -name '*.bin' -print0 | /usr/bin/xargs -0 /usr/bin/sha256sum | LC_ALL=C /usr/bin/sort | /usr/bin/awk '{c[$1]++; p[$1]=p[$1] " " $2} END {for (k in c) if (c[k]>1) print c[k], k}'

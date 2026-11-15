#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (compression).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'keep\n' > keep.txt
/usr/bin/bzip2 -c keep.txt > a.bz2
/usr/bin/bzip2 -dc a.bz2 | /usr/bin/cmp - keep.txt && /usr/bin/printf 'bzip2-ok\n'
/usr/bin/xz -c keep.txt > a.xz
/usr/bin/xz -dc a.xz | /usr/bin/cmp - keep.txt && /usr/bin/printf 'xz-ok\n'

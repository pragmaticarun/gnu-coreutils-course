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
/usr/bin/pigz -n -c keep.txt > a.gz
/usr/bin/gzip -dc a.gz | /usr/bin/cmp - keep.txt && /usr/bin/printf 'pigz-gzip-roundtrip\n'

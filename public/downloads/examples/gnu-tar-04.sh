#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (gnu-tar).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'keep\n' > keep.txt
/usr/bin/tar --owner=0 --group=0 --numeric-owner --mtime=@0 -cf bundle.tar keep.txt
/usr/bin/tar -tvf bundle.tar

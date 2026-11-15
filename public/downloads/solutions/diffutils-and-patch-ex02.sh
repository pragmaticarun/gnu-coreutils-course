#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (diffutils-and-patch).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'ax' > left
/usr/bin/printf 'ay' > right
/usr/bin/cmp left right >out || test $? -eq 1
/usr/bin/cat out

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (du-and-df).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/mkdir -p tree/sub
/usr/bin/printf 'hello\n' > tree/sub/f
/usr/bin/du -B1 -d 1 tree
/usr/bin/du -b -s tree

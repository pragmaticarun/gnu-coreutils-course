#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (parallel-compression).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/mkdir in out
/usr/bin/printf 'a\n' > in/a.txt
/usr/bin/printf 'b\n' > in/b.txt
/usr/bin/find in -type f -print0 | /usr/bin/xargs -0 -P 2 -I {} /bin/bash -c '/usr/bin/gzip -n -c "$1" > "out/$(/usr/bin/basename "$1").gz"' _ {}
/usr/bin/find out -type f -print | LC_ALL=C /usr/bin/sort
/usr/bin/gzip -dc out/a.txt.gz | /usr/bin/cmp - in/a.txt && /usr/bin/printf 'a-ok\n'

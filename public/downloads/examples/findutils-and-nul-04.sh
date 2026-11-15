#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (findutils-and-nul).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/mkdir tree
/usr/bin/printf 'hi\n' > tree/needle.txt
set +e
updatedb -U "$PWD/tree" -o "$PWD/locatedb" --prunepaths '' 2>upd.err
status=$?
set -e
/usr/bin/printf 'updatedb_status:%s\n' "$status"
/usr/bin/grep -F 'fchown' upd.err

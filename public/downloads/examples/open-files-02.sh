#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (open-files).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
exec 3>hold.txt
/usr/bin/rm hold.txt
/usr/bin/lsof -a -p $$ -d 3 | /usr/bin/grep -o '(deleted)'

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (gnu-grep).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'a.c\nabc\n' > names.txt
/usr/bin/printf 'fixed:\n'
/usr/bin/grep -F -n 'a.c' names.txt
/usr/bin/printf 'extended:\n'
/usr/bin/grep -E -n 'a.c' names.txt

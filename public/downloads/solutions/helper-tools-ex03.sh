#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (helper-tools).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'b\na\nb\n' > names.txt
LC_ALL=C /usr/bin/sort -u names.txt | /usr/bin/sponge names.txt
/usr/bin/cat names.txt

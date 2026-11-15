#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (awk-family).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'ok 2\nfail 5\nok 1\n' | /usr/bin/awk '{s += $2} END {print s}'

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (orientation).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
set +e
/usr/bin/ls /no/such/coreutils-orientation-path
status=$?
set -e
/usr/bin/printf 'status:%s\n' "$status"

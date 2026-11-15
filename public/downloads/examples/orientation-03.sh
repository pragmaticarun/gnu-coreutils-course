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
/usr/bin/true
/usr/bin/printf 'true:%s\n' $?
/usr/bin/false
/usr/bin/printf 'false:%s\n' $?
set -e

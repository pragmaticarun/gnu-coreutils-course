#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (process-wrappers).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
set +e
/usr/bin/timeout 1 /usr/bin/sleep 3
/usr/bin/printf 'default:%s\n' $?
/usr/bin/timeout --preserve-status 1 /usr/bin/sleep 3
/usr/bin/printf 'preserved:%s\n' $?
set -e

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (util-linux-toolbox).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/flock lock -c '/usr/bin/sleep 1' &
/usr/bin/sleep 0.2
set +e
/usr/bin/flock -n lock -c '/usr/bin/printf got\n'
status=$?
set -e
/usr/bin/printf 'second:%s\n' "$status"
wait || true

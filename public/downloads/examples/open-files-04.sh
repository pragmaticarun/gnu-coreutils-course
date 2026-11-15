#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (open-files).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'x\n' > closed.txt
set +e
/usr/bin/fuser closed.txt >/dev/null 2>/dev/null
status=$?
set -e
/usr/bin/printf 'fuser_closed:%s\n' "$status"

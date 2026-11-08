#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (orientation).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
set +e
/usr/bin/ls /no/such/coreutils-orientation-path
status=$?
set -e
/usr/bin/printf 'status:%s\n' "$status"

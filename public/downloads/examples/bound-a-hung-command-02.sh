#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (bound-a-hung-command).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
set +e
/usr/bin/timeout --preserve-status 1 /usr/bin/sleep 3
/usr/bin/printf 'preserved:%s\n' $?
set -e

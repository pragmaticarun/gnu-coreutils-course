#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (bound-a-hung-command).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
set +e
/usr/bin/timeout 1 /usr/bin/sleep 3
/usr/bin/printf 'timed_out:%s\n' $?
/usr/bin/timeout 2 /usr/bin/true
/usr/bin/printf 'finished:%s\n' $?
set -e

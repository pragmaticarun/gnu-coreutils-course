#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (process-wrappers).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/nice -n 5 /usr/bin/true
/usr/bin/printf 'raised:%s\n' $?
set +e
/usr/bin/nice -n -1 /usr/bin/true
/usr/bin/printf 'lower:%s\n' $?
set -e

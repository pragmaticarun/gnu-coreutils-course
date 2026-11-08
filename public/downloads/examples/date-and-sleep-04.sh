#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (date-and-sleep).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/sleep 0.05
/usr/bin/printf 'slept\n'
set +e
/usr/bin/sleep foo
/usr/bin/printf 'bad:%s\n' $?
set -e

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (test-and-expr).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
set +e
/usr/bin/expr 1 = 1
/usr/bin/printf 'eq:%s\n' $?
/usr/bin/expr 1 = 2
/usr/bin/printf 'ne:%s\n' $?
set -e

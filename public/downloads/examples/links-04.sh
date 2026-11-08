#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (links).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir box
set +e
/usr/bin/link box box2
/usr/bin/printf 'link:%s\n' $?
/usr/bin/unlink box
/usr/bin/printf 'unlink:%s\n' $?
set -e

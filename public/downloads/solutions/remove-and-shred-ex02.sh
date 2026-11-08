#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (remove-and-shred).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/touch a b c d
set +e
/usr/bin/rm -I a b c d
/usr/bin/printf 'status:%s\n' $?
set -e
/usr/bin/ls -1

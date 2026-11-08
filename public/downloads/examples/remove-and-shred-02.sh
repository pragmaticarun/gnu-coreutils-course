#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (remove-and-shred).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/touch f1 f2 f3 f4
set +e
/usr/bin/rm -I f1 f2 f3 f4
/usr/bin/printf 'status:%s\n' $?
set -e
/usr/bin/ls -1

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (head-and-tail).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -u

cd "$(mktemp -d)"
/usr/bin/printf 'hi\n' > log
/usr/bin/timeout 1 /usr/bin/tail -n 1 -f log

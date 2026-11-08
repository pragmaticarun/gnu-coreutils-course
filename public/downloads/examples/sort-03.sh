#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (sort).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -u

cd "$(mktemp -d)"
/usr/bin/printf 'b\na\n' | /usr/bin/sort -c

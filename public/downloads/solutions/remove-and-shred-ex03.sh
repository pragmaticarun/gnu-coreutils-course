#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (remove-and-shred).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'temp\n' > temp
/usr/bin/shred -u -n 1 temp
/usr/bin/ls -A

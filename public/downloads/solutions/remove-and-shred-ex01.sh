#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (remove-and-shred).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'x\n' > gone.txt
/usr/bin/rm -- gone.txt
/usr/bin/ls -A

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (cut-and-paste).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'x\n' > x
/usr/bin/printf 'y\n' > y
/usr/bin/paste x y

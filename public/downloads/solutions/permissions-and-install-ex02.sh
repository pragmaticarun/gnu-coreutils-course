#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (permissions-and-install).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -u

cd "$(mktemp -d)"
/usr/bin/printf 'x\n' > mine
/usr/bin/chown 0:0 mine

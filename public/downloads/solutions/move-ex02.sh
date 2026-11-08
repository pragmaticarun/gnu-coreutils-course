#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (move).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -u

cd "$(mktemp -d)"
/usr/bin/printf 'new\n' > src
/usr/bin/printf 'old\n' > dst
/usr/bin/cat dst
/usr/bin/mv -n src dst

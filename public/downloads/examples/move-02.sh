#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (move).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -u

cd "$(mktemp -d)"
/usr/bin/printf 'aaa\n' > a
/usr/bin/printf 'bbb\n' > b
/usr/bin/mv -n a b

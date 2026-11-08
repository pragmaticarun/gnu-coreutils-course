#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (move).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir d
/usr/bin/printf 'a\n' > a
/usr/bin/printf 'b\n' > b
/usr/bin/mv -t d a b
/usr/bin/ls -1 d

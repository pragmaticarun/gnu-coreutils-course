#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (move).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir dest
/usr/bin/printf '1\n' > one
/usr/bin/printf '2\n' > two
/usr/bin/mv -t dest one two
/usr/bin/ls -1 dest

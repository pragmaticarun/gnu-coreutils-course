#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (split-a-log).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf '1\n2\n3\n4\n5\n' > log
/usr/bin/split -l 2 log part_
/usr/bin/ls part_*

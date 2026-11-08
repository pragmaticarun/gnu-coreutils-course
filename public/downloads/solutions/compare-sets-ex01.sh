#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (compare-sets).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\nb\nc\n' > left
/usr/bin/printf 'b\nc\nd\n' > right
/usr/bin/comm -13 left right

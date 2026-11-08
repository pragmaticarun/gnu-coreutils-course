#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (join-and-comm).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\nb\nc\n' > l
/usr/bin/printf 'b\nc\nd\n' > r
/usr/bin/comm -12 l r

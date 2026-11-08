#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (join-and-comm).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a 1\nb 2\n' > l
/usr/bin/printf 'a X\nb Y\n' > r
/usr/bin/join l r

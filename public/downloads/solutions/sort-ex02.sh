#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (sort).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'b 2\nb 1\n' | /usr/bin/sort -k1,1 -s

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (counting-with-wc).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'abc' | /usr/bin/wc -c

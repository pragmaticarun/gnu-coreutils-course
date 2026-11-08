#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (split-and-csplit).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'abcdef' | /usr/bin/split -d -a 1 -n r/3 - r
/usr/bin/wc -c r*

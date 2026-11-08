#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (sort).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf '10\n2\n1\n' | /usr/bin/sort -n
/usr/bin/printf 'a10\na2\na1\n' | /usr/bin/sort -V

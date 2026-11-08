#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (uniq).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\nA\n' | /usr/bin/sort | /usr/bin/uniq -i

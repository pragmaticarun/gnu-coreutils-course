#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (tee-mktemp-pathchk).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'ab\n' | /usr/bin/tee a.txt b.txt >/dev/null
/usr/bin/wc -c a.txt b.txt

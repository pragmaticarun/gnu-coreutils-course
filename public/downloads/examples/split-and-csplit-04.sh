#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (split-and-csplit).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\n\nb\n' > blanks
/usr/bin/csplit -z -q -f z blanks '/^$/' '{*}'
/usr/bin/wc -c z*

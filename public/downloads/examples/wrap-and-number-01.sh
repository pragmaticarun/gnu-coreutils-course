#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (wrap-and-number).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'one two three four\n' | /usr/bin/fmt -w 10
/usr/bin/printf '> a b c d e\n' | /usr/bin/fmt -p '>' -w 8

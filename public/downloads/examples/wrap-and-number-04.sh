#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (wrap-and-number).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\n\nb\n' | /usr/bin/nl -ba -w2 -s' '
/usr/bin/printf 'a\nb\nc\nd\n' | /usr/bin/pr -t -2 -s,

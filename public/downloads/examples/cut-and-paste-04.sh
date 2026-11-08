#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (cut-and-paste).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\nb\n' > left
/usr/bin/printf '1\n2\n' > right
/usr/bin/paste left right
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/paste -s -d,

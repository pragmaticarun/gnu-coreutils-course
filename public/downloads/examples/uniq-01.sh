#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (uniq).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\nb\na\n' | /usr/bin/uniq -d | /usr/bin/wc -c
/usr/bin/printf 'a\na\nb\n' | /usr/bin/uniq -d

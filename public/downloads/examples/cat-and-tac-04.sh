#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (cat-and-tac).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a,b,c' | /usr/bin/tac -s,
/usr/bin/printf '\n---\n'
/usr/bin/printf 'a,b,c' | /usr/bin/tac -s, | /usr/bin/od -An -tx1c

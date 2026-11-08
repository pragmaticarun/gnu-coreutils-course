#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (cat-and-tac).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'hi\n' | /usr/bin/cat -A

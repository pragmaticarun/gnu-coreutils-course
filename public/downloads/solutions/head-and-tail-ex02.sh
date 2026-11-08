#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (head-and-tail).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'abcdef' | /usr/bin/tail -c 3
/usr/bin/printf '\n'

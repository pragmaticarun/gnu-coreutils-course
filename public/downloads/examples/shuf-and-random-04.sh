#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (shuf-and-random).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a b\nb c\n' | /usr/bin/tsort

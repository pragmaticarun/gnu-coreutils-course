#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (performance-mechanisms).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'b\nA\na\nB\n' | LC_ALL=C /usr/bin/sort
/usr/bin/printf '---\n'
/usr/bin/printf 'b\nA\na\nB\n' | LC_ALL=en_US.UTF-8 /usr/bin/sort

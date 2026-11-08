#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (split-and-csplit).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\nb\nc\nd\n' | /usr/bin/split -d -a 1 -l 2 - o
/usr/bin/ls -1 o*

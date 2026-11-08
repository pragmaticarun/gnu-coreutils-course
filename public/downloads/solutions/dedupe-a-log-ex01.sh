#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (dedupe-a-log).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'err\nerr\nerr\n' > log
/usr/bin/sort log | /usr/bin/uniq -c

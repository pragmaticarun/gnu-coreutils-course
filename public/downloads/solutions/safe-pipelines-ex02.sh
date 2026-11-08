#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (safe-pipelines).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
target=""
if test -z "$target" || test "$target" = /; then
  /usr/bin/printf 'refuse\n'
else
  /usr/bin/printf 'would-delete\n'
fi

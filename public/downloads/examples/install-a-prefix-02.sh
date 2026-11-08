#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (install-a-prefix).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
prefix=""
if test -z "$prefix" || test "$prefix" = /; then
  /usr/bin/printf 'refuse\n'
else
  /usr/bin/printf 'would-install\n'
fi

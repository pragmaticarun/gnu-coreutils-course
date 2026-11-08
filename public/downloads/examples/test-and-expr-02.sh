#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (test-and-expr).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
set +e
/usr/bin/test -e ./no-such-file
/usr/bin/printf 'exists:%s\n' $?
set -e

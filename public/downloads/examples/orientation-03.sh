#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (orientation).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
set +e
/usr/bin/true
/usr/bin/printf 'true:%s\n' $?
/usr/bin/false
/usr/bin/printf 'false:%s\n' $?
set -e

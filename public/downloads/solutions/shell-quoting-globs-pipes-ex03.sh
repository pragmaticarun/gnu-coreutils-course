#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (shell-quoting-globs-pipes).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
set +e
/usr/bin/ls ./missing-name
status=$?
set -e
/usr/bin/printf 'saw:%s\n' "$status"

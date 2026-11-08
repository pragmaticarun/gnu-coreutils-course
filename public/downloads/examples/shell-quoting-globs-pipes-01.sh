#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (shell-quoting-globs-pipes).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf '%s\n' 'a b' "a b" a b

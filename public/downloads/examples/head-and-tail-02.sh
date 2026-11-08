#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (head-and-tail).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'header\na\nb\n' | /usr/bin/tail -n +2

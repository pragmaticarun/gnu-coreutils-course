#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (head-and-tail).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/head -n -1

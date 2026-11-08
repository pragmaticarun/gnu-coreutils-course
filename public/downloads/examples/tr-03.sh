#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (tr).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'é' | /usr/bin/tr 'é' 'X' | /usr/bin/od -An -tx1

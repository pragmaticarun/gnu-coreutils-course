#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (wrap-and-number).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'éé\n' | /usr/bin/fold -w 1 | /usr/bin/od -An -tx1

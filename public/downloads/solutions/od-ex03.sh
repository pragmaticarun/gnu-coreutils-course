#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (od).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'abc' | /usr/bin/od -An -tx1

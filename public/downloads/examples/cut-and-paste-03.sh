#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (cut-and-paste).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'éx' | /usr/bin/cut -c1 | /usr/bin/od -An -tx1
/usr/bin/printf 'éx' | /usr/bin/cut -b1 | /usr/bin/od -An -tx1

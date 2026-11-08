#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (locale-and-byte-order).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'é' | /usr/bin/wc -m -c

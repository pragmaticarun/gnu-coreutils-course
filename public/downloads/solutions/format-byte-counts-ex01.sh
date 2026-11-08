#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (format-byte-counts).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf '4096\n' | /usr/bin/numfmt --to=iec

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (copy).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/truncate -s 1M hole
/usr/bin/cp --sparse=auto hole hole-copy
/usr/bin/stat -c 'src size=%s blocks=%b' hole
/usr/bin/stat -c 'dst size=%s blocks=%b' hole-copy

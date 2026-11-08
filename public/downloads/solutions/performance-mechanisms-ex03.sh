#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (performance-mechanisms).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'data\n' > src
/usr/bin/cp --reflink=auto src dst
/usr/bin/wc -c dst

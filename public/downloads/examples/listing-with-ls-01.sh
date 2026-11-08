#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (listing-with-ls).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir -p tree/sub
/usr/bin/printf 'x\n' > tree/file
/usr/bin/printf 'y\n' > tree/.hidden
/usr/bin/ln -s file tree/link
/usr/bin/ls -1 -A -F tree

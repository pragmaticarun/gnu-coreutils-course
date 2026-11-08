#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (copy).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'xyz\n' > a
/usr/bin/cp --reflink=never a b
/usr/bin/sha256sum a b

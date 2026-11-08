#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (copy).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'abc\n' > src
set +e
/usr/bin/cp --reflink=always src dest-always
/usr/bin/printf 'always:%s\n' $?
set -e
/usr/bin/cp --reflink=auto src dest-auto
/usr/bin/sha256sum src dest-auto

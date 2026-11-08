#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (shuf-and-random).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\nb\nc\nd\n' > items
/usr/bin/shuf --random-source=/dev/zero -n 2 items > one
/usr/bin/shuf --random-source=/dev/zero -n 2 items > two
/usr/bin/cat one
/usr/bin/sha256sum one two

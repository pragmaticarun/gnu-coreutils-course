#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (counting-with-wc).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\n' > 'a b'
/usr/bin/printf 'bb\n' > c
/usr/bin/printf 'a b\0c\0' | /usr/bin/wc -l --files0-from=-

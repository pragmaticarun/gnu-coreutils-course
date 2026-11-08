#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (split-and-csplit).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'one\nEND\n' > doc
/usr/bin/csplit -q -f p doc '/^END/'
/usr/bin/printf '0:\n'
/usr/bin/cat p00
/usr/bin/printf '1:\n'
/usr/bin/cat p01

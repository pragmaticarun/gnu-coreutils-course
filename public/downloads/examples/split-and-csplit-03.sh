#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (split-and-csplit).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'HEAD\n1\n2\nFOOT\n' > doc
/usr/bin/csplit -q -f part doc '/^FOOT/'
/usr/bin/printf 'part00:\n'
/usr/bin/cat part00
/usr/bin/printf 'part01:\n'
/usr/bin/cat part01

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (seq-numfmt-factor).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/seq 0 0.1 1
/usr/bin/printf 'lines:'
/usr/bin/seq 0 0.1 1 | /usr/bin/wc -l

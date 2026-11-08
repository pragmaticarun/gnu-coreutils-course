#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (seq-numfmt-factor).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/seq -w 8 10
/usr/bin/seq -s, 1 3

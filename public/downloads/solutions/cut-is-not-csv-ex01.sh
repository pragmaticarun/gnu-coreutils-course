#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (cut-is-not-csv).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a,"b,c",d\n' | /usr/bin/cut -d, -f2

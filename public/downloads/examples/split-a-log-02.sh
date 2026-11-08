#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (split-a-log).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'only\n' > one
/usr/bin/split -n r/3 one rr_
/usr/bin/wc -c rr_*

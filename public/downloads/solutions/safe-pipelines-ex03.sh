#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (safe-pipelines).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir -p scratch
/usr/bin/printf 'x\n' > scratch/file
/usr/bin/rm -rf -- scratch
/usr/bin/test ! -e scratch && /usr/bin/printf 'gone\n'

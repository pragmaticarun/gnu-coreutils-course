#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (safe-pipelines).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir nest
/usr/bin/printf 'x\n' > "$(/usr/bin/printf 'nest/a\nb')"
/usr/bin/ls --quoting-style=shell-escape nest

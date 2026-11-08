#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (safe-pipelines).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'hello world\n' > "my file"
/usr/bin/wc -c "my file"

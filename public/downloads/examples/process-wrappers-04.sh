#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (process-wrappers).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/nohup /usr/bin/printf 'hi\n' > redirected.out
/usr/bin/ls -1
/usr/bin/cat redirected.out

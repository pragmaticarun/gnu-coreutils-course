#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (wrap-and-number).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf '\ta\n' | /usr/bin/expand -t 4 | /usr/bin/cat -A

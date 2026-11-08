#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (base-encoding).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'aGVs bG8=\n' | /usr/bin/base64 -d -i
/usr/bin/printf '\n'

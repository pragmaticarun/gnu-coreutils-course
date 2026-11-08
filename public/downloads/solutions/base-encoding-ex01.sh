#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (base-encoding).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'hi' | /usr/bin/base64 -w 0
/usr/bin/printf '\n'

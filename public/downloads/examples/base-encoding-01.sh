#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (base-encoding).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'hello world' | /usr/bin/base64 -w 0
/usr/bin/printf '\n'
/usr/bin/printf 'aGVsbG8gd29ybGQ=' | /usr/bin/base64 -d
/usr/bin/printf '\n'

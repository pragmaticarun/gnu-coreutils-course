#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (reproducible-shuf).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\nb\nc\nd\n' > names
/usr/bin/shuf -n 2 --random-source=/dev/zero names

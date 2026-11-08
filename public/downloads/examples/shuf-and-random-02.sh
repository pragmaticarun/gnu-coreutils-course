#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (shuf-and-random).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/shuf --random-source=/dev/zero -n 3 -i 1-5

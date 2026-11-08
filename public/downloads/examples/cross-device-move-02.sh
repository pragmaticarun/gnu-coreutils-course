#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (cross-device-move).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'payload\n' > local
/usr/bin/mv local published
/usr/bin/cat published
/usr/bin/test ! -e local && /usr/bin/printf 'source-gone\n'

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (move).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'ok\n' > draft
/usr/bin/mv draft final
/usr/bin/cat final

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (nul-safe-names).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir box
/usr/bin/printf 'hello\n' > "box/my file"
/usr/bin/find box -type f -print0 | /usr/bin/xargs -0 /usr/bin/wc -c

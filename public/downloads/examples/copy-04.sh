#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (copy).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'new\n' > incoming
/usr/bin/printf 'old\n' > kept
/usr/bin/cp --update=none incoming kept
/usr/bin/cat kept

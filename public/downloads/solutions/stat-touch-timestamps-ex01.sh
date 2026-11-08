#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (stat-touch-timestamps).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'abcd' > payload
/usr/bin/stat -c '%s' payload

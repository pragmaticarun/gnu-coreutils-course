#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (version-sort).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a1\na10\na2\n' | /usr/bin/sort

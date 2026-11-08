#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (companion-tools).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'alpha\nbeta\n' | /usr/bin/grep -n beta

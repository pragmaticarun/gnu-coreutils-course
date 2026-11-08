#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (directories).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir empty
/usr/bin/rmdir empty
/usr/bin/ls -A

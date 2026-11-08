#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (directories).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir -p a/b/c
/usr/bin/rmdir -p a/b/c
/usr/bin/ls -A

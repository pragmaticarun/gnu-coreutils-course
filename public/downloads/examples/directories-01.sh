#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (directories).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'umask:'
umask
/usr/bin/mkdir -p -m 700 deep/leaf
/usr/bin/stat -c '%a %n' deep deep/leaf

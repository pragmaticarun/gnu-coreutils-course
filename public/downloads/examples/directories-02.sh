#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (directories).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
set +e
/usr/bin/mkdir box
/usr/bin/printf 'x\n' > box/file
/usr/bin/rmdir box
/usr/bin/printf 'nonempty:%s\n' $?
/usr/bin/rmdir box/file
/usr/bin/printf 'nota_dir:%s\n' $?
set -e

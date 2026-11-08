#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (links).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir dir
/usr/bin/printf 'z\n' > dir/file
/usr/bin/ln -sr dir/file dir/link
/usr/bin/readlink dir/link

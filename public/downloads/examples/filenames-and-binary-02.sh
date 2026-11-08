#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (filenames-and-binary).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir -p nest
name="$(/usr/bin/printf 'nest/a\nb')"
/usr/bin/touch "$name"
/usr/bin/ls -1 --quoting-style=shell-escape nest

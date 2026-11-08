#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (tee-mktemp-pathchk).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
dir=$(/usr/bin/mktemp -d ./work.XXXXXX)
/usr/bin/printf 'note\n' > "$dir/note.txt"
/usr/bin/cat "$dir/note.txt"

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (tee-mktemp-pathchk).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
file=$(/usr/bin/mktemp ./item.XXXXXX)
dir=$(/usr/bin/mktemp -d ./dir.XXXXXX)
/usr/bin/printf 'z\n' > "$file"
/usr/bin/printf 'file=%s\n' "$(/usr/bin/basename "$file")"
/usr/bin/printf 'dir_is_dir:'
/usr/bin/test -d "$dir" && /usr/bin/printf 'yes\n'

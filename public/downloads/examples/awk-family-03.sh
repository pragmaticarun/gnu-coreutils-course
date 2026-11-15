#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (awk-family).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'ab\n' | /usr/bin/gawk '{print gensub(/b/, "B", 1)}'
set +e
/usr/bin/printf 'ab\n' | /usr/bin/mawk '{print gensub(/b/, "B", 1)}' >mawk.out 2>mawk.err
status=$?
set -e
/usr/bin/printf 'mawk_status:%s\n' "$status"
/usr/bin/grep -F 'never defined' mawk.err

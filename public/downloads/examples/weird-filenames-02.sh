#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (weird-filenames).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/mkdir odd
/usr/bin/printf 'z\n' > "odd/a
name"
lines=$(/usr/bin/find odd -type f | /usr/bin/wc -l | /usr/bin/tr -d ' ')
nuls=$(/usr/bin/find odd -type f -print0 | /usr/bin/tr -cd '\0' | /usr/bin/wc -c | /usr/bin/tr -d ' ')
/usr/bin/printf 'lines:%s\nnuls:%s\n' "$lines" "$nuls"
bytes=$(/usr/bin/find odd -type f -print0 | /usr/bin/xargs -0 /usr/bin/wc -c | /usr/bin/awk '{s+=$1} END {print s}')
/usr/bin/printf 'bytes:%s\n' "$bytes"

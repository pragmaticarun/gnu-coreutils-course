#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (findutils-and-nul).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/mkdir box
/usr/bin/printf 'y\n' > "box/a
name"
lines=$(/usr/bin/find box -type f | /usr/bin/wc -l | /usr/bin/tr -d ' ')
nuls=$(/usr/bin/find box -type f -print0 | /usr/bin/tr -cd '\0' | /usr/bin/wc -c | /usr/bin/tr -d ' ')
/usr/bin/printf 'lines:%s\nnuls:%s\n' "$lines" "$nuls"

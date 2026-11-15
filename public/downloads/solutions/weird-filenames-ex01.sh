#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (weird-filenames).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/mkdir box
/usr/bin/printf 'abc\n' > "box/my file"
/usr/bin/find box -type f -print0 | /usr/bin/xargs -0 /usr/bin/sha256sum

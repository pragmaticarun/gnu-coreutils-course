#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (copy).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'data\n' > target
/usr/bin/ln -s target link
/usr/bin/cp -a link copy-link
/usr/bin/cp -L link copy-file
/usr/bin/stat -c '%F %n' copy-link copy-file

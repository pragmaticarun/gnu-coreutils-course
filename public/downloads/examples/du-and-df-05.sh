#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (du-and-df).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/dd if=/dev/zero of=hold.bin bs=4096 count=1 status=none
exec 9<>hold.bin
/usr/bin/rm -f hold.bin
if [ -e hold.bin ]; then
  /usr/bin/printf 'name_still_there\n'
  exit 1
fi
/usr/bin/printf 'name_gone\n'
/usr/bin/stat -L -c 'fd_size=%s' /proc/$$/fd/9
/usr/bin/wc -c < /proc/$$/fd/9
exec 9>&-

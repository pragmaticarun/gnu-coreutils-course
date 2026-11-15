#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (gnu-tar).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/truncate -s 1M hole
/usr/bin/tar --sparse -cf sparse.tar hole
/usr/bin/tar --format=posix -cf plain.tar hole
/usr/bin/wc -c sparse.tar plain.tar
/usr/bin/stat -c %s hole
/usr/bin/du -B1 hole | /usr/bin/awk '{print $1}'

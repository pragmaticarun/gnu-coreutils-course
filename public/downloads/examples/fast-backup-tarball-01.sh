#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (fast-backup-tarball).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/mkdir src
/usr/bin/printf 'keep\n' > src/keep.txt
/usr/bin/printf 'nope\n' > src/junk.o
/usr/bin/tar --exclude='*.o' --sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 -cf - -C src . | /usr/bin/zstd -q -T1 -o backup.tar.zst
/usr/bin/sha256sum backup.tar.zst
/usr/bin/mkdir restore
/usr/bin/zstd -q -dc backup.tar.zst | /usr/bin/tar -xf - -C restore
/usr/bin/cmp src/keep.txt restore/keep.txt && /usr/bin/printf 'member-matches\n'
/usr/bin/test ! -e restore/junk.o && /usr/bin/printf 'junk-excluded\n'

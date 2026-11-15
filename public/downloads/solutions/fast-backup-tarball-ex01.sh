#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (fast-backup-tarball).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'keep\n' > keep.txt
/usr/bin/tar --owner=0 --group=0 --numeric-owner --mtime=@0 -cf - keep.txt | /usr/bin/zstd -q -T1 -o one.tar.zst
/usr/bin/mkdir out
/usr/bin/zstd -q -dc one.tar.zst | /usr/bin/tar -xf - -C out
/usr/bin/cmp keep.txt out/keep.txt && /usr/bin/printf 'member-matches\n'

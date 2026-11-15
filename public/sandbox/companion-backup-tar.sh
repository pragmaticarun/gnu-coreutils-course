#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
mkdir src
printf 'keep\n' > src/keep.txt
printf 'nope\n' > src/junk.o
tar --exclude='*.o' --sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 -cf - -C src . | zstd -q -T1 -o a.tar.zst
tar --exclude='*.o' --sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 -cf - -C src . | zstd -q -T1 -o b.tar.zst
cmp a.tar.zst b.tar.zst || fail "archives differ"
mkdir restore
zstd -q -dc a.tar.zst | tar -xf - -C restore
cmp src/keep.txt restore/keep.txt || fail "member"
[[ ! -e restore/junk.o ]] || fail "junk kept"
printf 'ok companion-backup-tar\n'

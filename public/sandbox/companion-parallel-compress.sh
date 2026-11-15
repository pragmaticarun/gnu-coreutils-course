#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
printf 'payload\n' > blob
pigz -n -p1 -c blob > blob.gz
gzip -dc blob.gz | cmp - blob || fail "pigz"
zstd -q -T1 -c blob > blob.zst
zstd -q -dc blob.zst | cmp - blob || fail "zstd"
mkdir in out
printf 'a\n' > in/a.txt
printf 'b\n' > in/b.txt
find in -type f -print0 | xargs -0 -P 2 -I {} bash -c 'gzip -n -c "$1" > "out/$(basename "$1").gz"' _ {}
gzip -dc out/a.txt.gz | cmp - in/a.txt || fail "a"
gzip -dc out/b.txt.gz | cmp - in/b.txt || fail "b"
printf 'ok companion-parallel-compress\n'

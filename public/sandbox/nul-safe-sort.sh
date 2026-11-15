#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
count=$(printf 'b\0a\nname\0a\0' | LC_ALL=C sort -z | tr -cd '\0' | wc -c)
[[ "$count" -eq 3 ]] || fail "records $count"
mkdir -p names
printf x > names/b.txt
printf x > "names/a
name.txt"
nuls=$(find names -type f -print0 | LC_ALL=C sort -z | tr -cd '\0' | wc -c)
lines=$(find names -type f | wc -l)
[[ "$nuls" -eq 2 ]] || fail "nuls $nuls"
[[ "$lines" -eq 3 ]] || fail "lines $lines"
printf 'ok nul-safe-sort\n'

#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
mkdir box
printf 'abc\n' > "box/my file"
printf 'z\n' > "box/a
name"
nuls=$(find box -type f -print0 | tr -cd '\0' | wc -c | tr -d ' ')
lines=$(find box -type f | wc -l | tr -d ' ')
[[ "$nuls" == 2 ]] || fail "nuls $nuls"
[[ "$lines" == 3 ]] || fail "lines $lines"
bytes=$(find box -type f -print0 | xargs -0 cat | wc -c | tr -d ' ')
[[ "$bytes" == 6 ]] || fail "bytes $bytes"
printf 'ok companion-weird-names\n'

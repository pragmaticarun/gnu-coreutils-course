#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
mkdir tree
printf 'same\n' > tree/a.bin
printf 'same\n' > tree/b.bin
truncate -s 1M tree/hole
apparent=$(find tree -type f -name hole -printf '%s')
[[ "$apparent" == 1048576 ]] || fail "apparent $apparent"
allocated=$(du -B1 tree/hole | awk '{print $1}')
[[ "$allocated" == 0 ]] || fail "allocated $allocated"
same=$(find tree -type f -name '*.bin' -print0 | xargs -0 sha256sum | awk '{print $1}' | uniq | wc -l | tr -d ' ')
[[ "$same" == 1 ]] || fail "digests $same"
printf 'ok companion-large-dupes\n'

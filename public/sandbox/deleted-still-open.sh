#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
dd if=/dev/zero of=hold.bin bs=4096 count=1 status=none
exec 9<>hold.bin
rm -f hold.bin
[[ ! -e hold.bin ]] || fail "name remains"
size=$(stat -L -c '%s' /proc/$$/fd/9)
[[ "$size" == 4096 ]] || fail "fd size $size"
exec 9>&-
printf 'ok deleted-still-open\n'

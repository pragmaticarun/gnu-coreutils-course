#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
printf '%s\n' '{"items":[{"name":"libfoo","arch":"arm64"},{"name":"libbar","arch":"amd64"}]}' > api.json
name=$(jq -r '.items[] | select(.arch=="arm64") | .name' api.json)
[[ "$name" == libfoo ]] || fail "name $name"
sorted=$(jq -r '.items[].name' api.json | LC_ALL=C sort | tr '\n' ',')
[[ "$sorted" == libbar,libfoo, ]] || fail "sorted $sorted"
printf 'ok companion-json\n'

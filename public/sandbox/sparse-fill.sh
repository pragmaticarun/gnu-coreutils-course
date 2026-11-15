#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
truncate -s 1M hole
cp --sparse=always hole kept
cp --sparse=never hole filled
kept_alloc=$(du -B1 kept | awk '{print $1}')
filled_alloc=$(du -B1 filled | awk '{print $1}')
[[ "$kept_alloc" -eq 0 ]] || fail "always allocated $kept_alloc"
[[ "$filled_alloc" -eq 1048576 ]] || fail "never allocated $filled_alloc"
printf 'ok sparse-fill\n'

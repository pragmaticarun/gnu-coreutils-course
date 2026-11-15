#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
mkdir -p target/debug target/release
truncate -s 5M target/debug/deps.rlib
truncate -s 1M target/release/demo
release=$(du -d 1 -b target | awk '$2=="target/release" { print $1 }')
debug=$(du -d 1 -b target | awk '$2=="target/debug" { print $1 }')
[[ "$debug" -gt "$release" ]] || fail "debug $debug release $release"
formatted=$(du -b target/release/demo target/debug/deps.rlib | LC_ALL=C sort -n | numfmt --field=1 --to=iec --padding=1)
[[ "$formatted" == *"1.0M target/release/demo"* ]] || fail "format $formatted"
[[ "$formatted" == *"5.0M target/debug/deps.rlib"* ]] || fail "format $formatted"
printf 'ok build-tree-weight\n'

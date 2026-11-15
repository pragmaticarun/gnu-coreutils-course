#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
mkdir -p out
umask 077
tmp=$(mktemp ./out/app-release.apk.XXXXXX)
[[ "$(dirname "$tmp")" == ./out ]] || fail "temp dir $(dirname "$tmp")"
printf 'finished-bytes\n' > "$tmp"
chmod 0644 "$tmp"
mv -f -- "$tmp" ./out/app-release.apk
[[ ! -e "$tmp" ]] || fail "temp remains"
[[ "$(cat out/app-release.apk)" == finished-bytes ]] || fail bytes
[[ "$(stat -c '%a' out/app-release.apk)" == 644 ]] || fail mode
printf 'ok atomic-publish\n'

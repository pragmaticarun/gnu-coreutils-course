#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
if ! env -i printf 'ok\n' >/dev/null; then
  fail "env -i printf should use the default search path on this GNU env"
fi
if env -i PATH= printf 'ok\n' >/dev/null 2>&1; then
  fail "env -i PATH= printf should fail"
fi
env -i PATH= /usr/bin/printf 'ok\n' >/dev/null || fail "absolute printf should ignore PATH"
printf 'ok env-empty-path\n'

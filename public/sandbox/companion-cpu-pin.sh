#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
affinity=$(taskset -c 0 bash --noprofile --norc -c 'taskset -c -p $$' | sed 's/.*: //')
[[ "$affinity" == 0 ]] || fail "affinity $affinity"
printf 'abc\n' > blob
sha256sum blob > free.sum
taskset -c 0 sha256sum blob > pinned.sum
cmp free.sum pinned.sum || fail "sums"
printf 'ok companion-cpu-pin\n'

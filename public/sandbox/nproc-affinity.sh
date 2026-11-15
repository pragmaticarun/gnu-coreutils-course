#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
command -v taskset >/dev/null || { printf 'FAIL: taskset (util-linux) is required\n' >&2; exit 1; }
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
all=$(nproc --all)
one=$(taskset -c 0 nproc)
[[ "$all" -ge 1 ]] || fail "nproc --all"
[[ "$one" == 1 ]] || fail "masked nproc $one"
printf 'ok nproc-affinity all=%s masked=%s\n' "$all" "$one"

#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
printf '%s\n' 'INFO start' 'ERROR linker missing libfoo' 'ERROR linker missing libfoo' > build.log
count=$(LC_ALL=C grep -F ERROR build.log | sed 's/^ERROR //' | awk '{c[$0]++} END {print c["linker missing libfoo"]}')
[[ "$count" == 2 ]] || fail "count $count"
printf 'ok companion-log-triage\n'

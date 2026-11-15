#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
printf '%s\n' 'INFO 1' 'ERROR 2' 'ERROR 5' > log
pipe=$(grep -F ERROR log | sed 's/^ERROR //' | awk '{s+=$1} END {print s}')
one=$(awk '/^ERROR / {s+=$2} END {print s}' log)
[[ "$pipe" == "$one" ]] || fail "pipe $pipe one $one"
[[ "$one" == 7 ]] || fail "total $one"
/usr/bin/time -f 'exit:%x' awk '/^ERROR / {s+=$2} END {print s}' log >/dev/null 2>time.err
grep -qx 'exit:0' time.err || fail "time $(cat time.err)"
printf 'ok companion-profile-pipeline\n'

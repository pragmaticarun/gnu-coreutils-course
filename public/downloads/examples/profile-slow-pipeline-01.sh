#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (profile-slow-pipeline).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf '%s\n' 'INFO 1' 'ERROR 2' 'ERROR 5' > log
pipe=$(LC_ALL=C /usr/bin/grep -F ERROR log | /usr/bin/sed 's/^ERROR //' | /usr/bin/awk '{s+=$1} END {print s}')
one=$(/usr/bin/awk '/^ERROR / {s+=$2} END {print s}' log)
/usr/bin/printf 'pipe:%s\none:%s\n' "$pipe" "$one"
/usr/bin/test "$pipe" = "$one" && /usr/bin/printf 'totals-match\n'

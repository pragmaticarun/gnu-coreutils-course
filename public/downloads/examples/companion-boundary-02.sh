#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (companion-boundary).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
type time
set +e
{ time -f %x /usr/bin/true; } >kw.out 2>kw.err
status=$?
set -e
printf 'keyword_status:%s\n' "$status"
grep -F 'command not found' kw.err
/usr/bin/time -f 'exit:%x' /usr/bin/true >/dev/null 2>gnu.err
cat gnu.err

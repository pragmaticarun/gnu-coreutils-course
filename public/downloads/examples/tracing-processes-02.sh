#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (tracing-processes).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/strace -c -e trace=write -o summary /usr/bin/echo hello >/dev/null
/usr/bin/grep -q write summary && /usr/bin/printf 'strace-c-saw-write\n'

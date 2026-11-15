#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (tracing-processes).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/strace -e write -o trace /usr/bin/echo hello >/dev/null
/usr/bin/sed -E 's/0x[0-9a-f]+/ADDR/g; s/= [0-9]+$/= N/' trace

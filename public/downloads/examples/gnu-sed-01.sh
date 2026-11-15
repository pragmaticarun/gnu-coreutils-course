#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (gnu-sed).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/sed -n '2p'
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/sed 's/b/B/'

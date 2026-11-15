#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (gnu-sed).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'a\nb\n' > source
/usr/bin/sed 's/b/B/' source > next
/usr/bin/printf 'source:%s' "$(/usr/bin/cat source)"
/usr/bin/printf 'next:%s' "$(/usr/bin/cat next)"

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (gnu-parallel).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/mkdir names
/usr/bin/printf '1\n' > "names/my file"
/usr/bin/find names -type f -print0 | /usr/bin/parallel --will-cite -0 /usr/bin/wc -c

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (gnu-sed).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'a\n' > seen
/usr/bin/ln seen hard
/usr/bin/stat -c %i seen > before
/usr/bin/sed -i 's/a/A/' seen
/usr/bin/stat -c %i seen > after
if /usr/bin/cmp -s before after; then /usr/bin/printf 'same-inode\n'; else /usr/bin/printf 'new-inode\n'; fi
/usr/bin/printf 'sed:%s\n' "$(cat seen)"
/usr/bin/printf 'hard:%s\n' "$(cat hard)"

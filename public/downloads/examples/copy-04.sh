#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (copy).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/truncate -s 1M hole
/usr/bin/cp --sparse=always hole kept
/usr/bin/cp --sparse=never hole filled
/usr/bin/stat -c 'kept size=%s blocks=%b' kept
/usr/bin/stat -c 'filled size=%s blocks=%b' filled
/usr/bin/du -B1 kept filled

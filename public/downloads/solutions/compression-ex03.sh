#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (compression).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'keep\n' > keep
/usr/bin/zstd -q -T1 -c keep > keep.zst
/usr/bin/zstd -q -dc keep.zst | /usr/bin/cmp - keep && /usr/bin/printf 'zstd-ok\n'

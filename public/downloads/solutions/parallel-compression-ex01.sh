#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (parallel-compression).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'payload\n' > blob
/usr/bin/zstd -q -T1 -c blob > blob.zst
/usr/bin/zstd -q -dc blob.zst | /usr/bin/cmp - blob && /usr/bin/printf 'zstd-ok\n'

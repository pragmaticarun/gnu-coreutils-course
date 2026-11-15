#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (cpu-pinned-benchmark).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'abc\n' > blob
/usr/bin/sha256sum blob > free.sum
/usr/bin/taskset -c 0 /usr/bin/sha256sum blob > pinned.sum
/usr/bin/cmp free.sum pinned.sum && /usr/bin/printf 'sums-match\n'

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (timing-tools).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/hyperfine --shell=none --runs 1 -- /usr/bin/true >hyp.txt 2>&1
/usr/bin/test -s hyp.txt && /usr/bin/printf 'hyperfine-ran\n'

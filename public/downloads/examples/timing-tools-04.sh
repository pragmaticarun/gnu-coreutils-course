#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (timing-tools).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/hyperfine --shell=none --warmup 1 --runs 3 -- /usr/bin/true >hyp.txt 2>&1 || true
/usr/bin/sed -E 's/[0-9]+([.][0-9]+)?/N/g' hyp.txt

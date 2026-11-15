#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (build-tree-weight).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
mkdir -p target/debug target/release
truncate -s 5M target/debug/deps.rlib
truncate -s 1M target/release/demo
du -d 1 -b target | LC_ALL=C sort -n

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (nul-safe-sort).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
printf 'b\0a\nname\0a\0' | LC_ALL=C sort -z | tr -cd '\0' | wc -c

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (util-linux-toolbox).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/prlimit --nofile=64 /usr/bin/bash --noprofile --norc -c 'ulimit -n'

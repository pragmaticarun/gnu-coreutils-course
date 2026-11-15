#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (process-wrappers).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/nproc
/usr/bin/nproc --all
/usr/bin/nproc --ignore=1
/usr/bin/ls -l /usr/libexec/coreutils/libstdbuf.so

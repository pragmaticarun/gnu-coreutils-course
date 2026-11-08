#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (reflink-fallback).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'data\n' > src
set +e
/usr/bin/cp --reflink=always src dst
/usr/bin/printf 'always:%s\n' $?
set -e

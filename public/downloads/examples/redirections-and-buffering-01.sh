#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (redirections-and-buffering).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
set +e
/usr/bin/ls . missing-stream > out.txt 2> err.txt
status=$?
set -e
/usr/bin/printf 'status:%s\n' "$status"
/usr/bin/printf 'stdout-file:\n'
/usr/bin/cat out.txt
/usr/bin/printf 'stderr-file:\n'
/usr/bin/cat err.txt

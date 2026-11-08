#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (redirections-and-buffering).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
set +e
/usr/bin/ls . missing-ex > ok.txt 2> bad.txt
set -e
/usr/bin/printf 'OK\n'
/usr/bin/cat ok.txt
/usr/bin/printf 'BAD\n'
/usr/bin/cat bad.txt

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (redirections-and-buffering).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'ab\n' | /usr/bin/stdbuf -o0 /usr/bin/cat | /usr/bin/od -An -tx1

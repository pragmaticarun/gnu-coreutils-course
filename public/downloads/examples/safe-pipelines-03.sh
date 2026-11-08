#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (safe-pipelines).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir -p build/obj
/usr/bin/printf 'o\n' > build/obj/a.o
/usr/bin/rm -rf -- build
/usr/bin/test ! -e build && /usr/bin/printf 'gone\n'

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (helper-tools).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/mkdir proj
/usr/bin/printf 'secret\n' > proj/skip.log
/usr/bin/printf 'keep me\n' > proj/main.txt
/usr/bin/printf '*.log\n' > proj/.gitignore
/usr/bin/mkdir proj/.git
/usr/bin/rg -n . proj
/usr/bin/printf 'ignored-too:\n'
/usr/bin/rg -n --no-ignore secret proj
/usr/bin/mkdir tree
/usr/bin/printf x > tree/widget.rs
/usr/bin/fdfind -t f . tree

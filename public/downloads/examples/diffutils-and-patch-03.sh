#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (diffutils-and-patch).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'a\nb\nc\n' > base
/usr/bin/printf 'a\nB\nc\n' > mine
/usr/bin/printf 'a\nb\nC\n' > theirs
/usr/bin/sdiff -s mine theirs >side.txt || test $? -eq 1
/usr/bin/cat side.txt
/usr/bin/diff3 mine base theirs >three.txt || test $? -eq 1
/usr/bin/grep -c . three.txt

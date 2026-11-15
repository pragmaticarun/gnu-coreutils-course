#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (diffutils-and-patch).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'a\nb\n' > old
/usr/bin/printf 'a\nB\n' > new
/usr/bin/diff -u old new >p.diff || test $? -eq 1
/usr/bin/cp old work
/usr/bin/patch work p.diff
/usr/bin/cmp work new && /usr/bin/printf 'matches-new\n'

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (helper-tools).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'b\na\nb\n' > names.txt
LC_ALL=C /usr/bin/sort -u names.txt | /usr/bin/sponge names.txt
/usr/bin/cat names.txt
/usr/bin/printf 'line\n' | /usr/bin/ts | /usr/bin/grep -q 'line$' && /usr/bin/printf 'ts-prefixed\n'
/usr/bin/printf 'x\n' | /usr/bin/ifne /usr/bin/printf 'had-input\n'
/usr/bin/printf '' | /usr/bin/ifne /usr/bin/printf 'should-not\n'
/usr/bin/printf 'after-ifne\n'
/usr/bin/chronic /usr/bin/printf 'hidden\n'
/usr/bin/printf 'chronic-ok\n'
/usr/bin/printf 'x\n' > watched
/usr/bin/printf 'watched\n' | /usr/bin/entr -nz /usr/bin/printf 'ran-once\n'

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (gnu-grep).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf 'a\0b\nhello\n' > bin.txt
set +e
/usr/bin/grep -F hello bin.txt >text.out 2>text.err
status=$?
set -e
/usr/bin/printf 'status:%s\n' "$status"
cat text.err
/usr/bin/printf 'with-a:\n'
/usr/bin/grep -a -F hello bin.txt

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (identity-and-host).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'users:[%s]\n' "$(/usr/bin/users)"
/usr/bin/printf 'who_lines:%s\n' "$(/usr/bin/who | /usr/bin/wc -l)"
set +e
/usr/bin/logname
/usr/bin/printf 'logname:%s\n' $?
/usr/bin/tty
/usr/bin/printf 'tty:%s\n' $?
set -e

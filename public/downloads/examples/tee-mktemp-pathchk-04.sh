#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (tee-mktemp-pathchk).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/pathchk -p 'ok_name'
set +e
/usr/bin/pathchk -p "$(/usr/bin/printf 'bad\nname')"
/usr/bin/printf 'path_status:%s\n' $?
set -e
/usr/bin/mkfifo fifo
set +e
/usr/bin/timeout 1 /usr/bin/cat fifo
/usr/bin/printf 'fifo_status:%s\n' $?
set -e

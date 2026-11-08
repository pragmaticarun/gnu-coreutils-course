#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (printf-echo-yes).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
set +e
bash -c 'set -o pipefail; yes | /usr/bin/head -n 2'
/usr/bin/printf 'pipefail:%s\n' $?
set -e

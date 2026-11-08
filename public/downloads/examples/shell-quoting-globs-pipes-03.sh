#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (shell-quoting-globs-pipes).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
set +e
bash -c '/usr/bin/printf a | /usr/bin/false | /usr/bin/true'
/usr/bin/printf 'nopf:%s\n' $?
bash -c 'set -o pipefail; /usr/bin/printf a | /usr/bin/false | /usr/bin/true'
/usr/bin/printf 'pf:%s\n' $?
set -e

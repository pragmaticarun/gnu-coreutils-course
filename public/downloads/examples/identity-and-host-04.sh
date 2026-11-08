#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (identity-and-host).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'x\n' > unlabeled
set +e
/usr/bin/id -Z
/usr/bin/printf 'idz:%s\n' $?
/usr/bin/chcon -t user_home_t unlabeled
/usr/bin/printf 'chcon:%s\n' $?
/usr/bin/runcon -t user_home_t /usr/bin/true
/usr/bin/printf 'runcon:%s\n' $?
set -e

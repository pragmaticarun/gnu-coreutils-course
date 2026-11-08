#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (process-wrappers).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/env -C /tmp /usr/bin/pwd
set +e
/usr/bin/env -u HOME /usr/bin/printenv HOME
/usr/bin/printf 'home_status:%s\n' $?
set -e
/usr/bin/env -i PATH=/usr/bin /usr/bin/printf 'clean\n'

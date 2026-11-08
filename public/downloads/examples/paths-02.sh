#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (paths).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/realpath -m /tmp/does-not-exist-cu/child
set +e
/usr/bin/realpath -e /tmp/does-not-exist-cu
/usr/bin/printf 'strict:%s\n' $?
set -e

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (orientation).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
dpkg-query -W -f 'coreutils ${Version}\n' coreutils
/usr/bin/ls --version | /usr/bin/head -n 1

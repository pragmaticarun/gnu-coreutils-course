#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (permissions-and-install).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'x\n' > src
/usr/bin/printf 'y\n' > dst
/usr/bin/chmod 600 src
/usr/bin/chmod --reference=src dst
/usr/bin/stat -c '%a %n' dst

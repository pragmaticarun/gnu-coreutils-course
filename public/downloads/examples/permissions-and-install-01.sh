#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (permissions-and-install).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'x\n' > a
/usr/bin/printf 'y\n' > b
/usr/bin/chmod 640 a
/usr/bin/chmod u=rw,go= b
/usr/bin/stat -c '%a %A %n' a b

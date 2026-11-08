#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (directories).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -u

cd "$(mktemp -d)"
/usr/bin/mkdir full
/usr/bin/printf 'z\n' > full/item
/usr/bin/rmdir full

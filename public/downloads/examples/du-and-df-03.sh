#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (du-and-df).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir box
/usr/bin/printf 'hello\n' > box/a
/usr/bin/link box/a box/b
/usr/bin/du -B1 -s box
/usr/bin/du -B1 -s -l box

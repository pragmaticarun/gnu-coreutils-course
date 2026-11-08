#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (join-and-comm).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -u

cd "$(mktemp -d)"
/usr/bin/printf 'b 1\na 2\n' > l
/usr/bin/printf 'a x\nb y\n' > r
/usr/bin/join l r

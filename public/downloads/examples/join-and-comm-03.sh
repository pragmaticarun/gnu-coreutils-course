#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (join-and-comm).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'b 1\na 2\n' > messy
/usr/bin/printf 'a x\nb y\n' > tidy
/usr/bin/join --nocheck-order messy tidy
/usr/bin/printf 'status-was-zero\n'

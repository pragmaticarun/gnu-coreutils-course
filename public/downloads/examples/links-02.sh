#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (links).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir -p sub
/usr/bin/printf 'x\n' > sub/target
/usr/bin/ln -sr sub/target the-link
/usr/bin/readlink the-link

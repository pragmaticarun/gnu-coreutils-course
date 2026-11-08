#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (links).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'same\n' > a
/usr/bin/ln a b
/usr/bin/stat -c '%h %i %n' a b
/usr/bin/unlink b
/usr/bin/stat -c '%h %n' a

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (seq-numfmt-factor).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf '2048\n' | /usr/bin/numfmt --to=iec
/usr/bin/printf '2048\n' | /usr/bin/numfmt --to=si
/usr/bin/printf 'x 2048 y\n' | /usr/bin/numfmt --field=2 --to=iec

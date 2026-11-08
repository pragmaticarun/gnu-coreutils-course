#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (join-tables).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
set +e
/usr/bin/printf '2 blue\n1 red\n' > colors
/usr/bin/printf '1 apple\n2 berry\n' > fruit
/usr/bin/join colors fruit
/usr/bin/printf 'status:%s\n' $?
set -e

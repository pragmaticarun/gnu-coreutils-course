#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (join-tables).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf '1 red\n2 blue\n' > colors
/usr/bin/printf '1 apple\n2 berry\n' > fruit
/usr/bin/join colors fruit

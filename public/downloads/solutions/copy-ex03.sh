#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (copy).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'keep\n' > old
/usr/bin/printf 'replace\n' > new
/usr/bin/cp --update=none new old
/usr/bin/cat old

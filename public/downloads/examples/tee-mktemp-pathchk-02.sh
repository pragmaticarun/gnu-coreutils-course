#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (tee-mktemp-pathchk).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'one\n' > log.txt
/usr/bin/printf 'two\n' | /usr/bin/tee -a log.txt >/dev/null
/usr/bin/cat log.txt

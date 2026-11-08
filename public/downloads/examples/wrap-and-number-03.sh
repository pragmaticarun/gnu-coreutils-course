#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (wrap-and-number).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\tb\n' | /usr/bin/expand -t 4 | /usr/bin/cat -A
/usr/bin/printf 'a   b\n' | /usr/bin/unexpand -t 4 | /usr/bin/cat -A

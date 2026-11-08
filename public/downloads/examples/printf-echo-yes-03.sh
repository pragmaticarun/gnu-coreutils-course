#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (printf-echo-yes).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'default:'
/usr/bin/echo 'a\tb'
/usr/bin/printf 'dash-e:'
/usr/bin/echo -e 'a\tb'

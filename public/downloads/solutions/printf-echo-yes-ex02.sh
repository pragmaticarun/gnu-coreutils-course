#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (printf-echo-yes).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
echo --help
/usr/bin/echo --help | /usr/bin/head -n 1

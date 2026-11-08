#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (orientation).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
type -a echo
echo --help
/usr/bin/echo --version | /usr/bin/head -n 1

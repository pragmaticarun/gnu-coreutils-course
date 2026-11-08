#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (developer-workflow).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/nproc
/usr/bin/nproc --ignore=1

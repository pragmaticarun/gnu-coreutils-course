#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (links).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/ln -s old name
/usr/bin/ln -sfn new name
/usr/bin/readlink name

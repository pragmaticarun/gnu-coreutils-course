#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (sparse-apparent-size).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/truncate -s 1M hole
/usr/bin/ls -l hole

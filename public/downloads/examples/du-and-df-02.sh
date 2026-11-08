#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (du-and-df).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/truncate -s 1M hole
/usr/bin/stat -c 'size=%s blocks=%b unit=%B' hole
/usr/bin/du -B1 hole
/usr/bin/du -b hole

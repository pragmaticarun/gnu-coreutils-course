#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (listing-with-ls).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'hello\n' > notes.txt
/usr/bin/ls -l --block-size=1 notes.txt
/usr/bin/ls -l -h notes.txt

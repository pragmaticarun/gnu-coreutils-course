#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (filenames-and-binary).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/touch 'a b' c
/usr/bin/ls -1 --zero | /usr/bin/od -An -tx1

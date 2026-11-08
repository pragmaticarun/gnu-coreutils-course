#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (filenames-and-binary).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\nb' > bytes
/usr/bin/od -An -tx1 bytes

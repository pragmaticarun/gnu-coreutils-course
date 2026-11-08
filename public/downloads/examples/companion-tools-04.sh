#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (companion-tools).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\n' > file.txt
/usr/bin/tar -cf bundle.tar file.txt
/usr/bin/tar -tf bundle.tar

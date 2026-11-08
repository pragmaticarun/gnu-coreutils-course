#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (checksums).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -u

cd "$(mktemp -d)"
/usr/bin/printf 'abc' > payload
/usr/bin/printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  payload\n' | /usr/bin/sha256sum -c -

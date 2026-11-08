#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (reproducible-shuf).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\nb\nc\nd\n' > names
/usr/bin/shuf --random-source=/dev/zero names > one
/usr/bin/shuf --random-source=/dev/zero names > two
/usr/bin/sha256sum one two

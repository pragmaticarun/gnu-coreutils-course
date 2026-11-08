#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (verify-a-manifest).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'payload\n' > blob
/usr/bin/sha256sum blob > MANIFEST
/usr/bin/printf 'other\n' > blob
set +e
/usr/bin/sha256sum -c MANIFEST
/usr/bin/printf 'status:%s\n' $?
set -e

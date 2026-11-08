#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (permissions-and-install).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'hide\n' > secret
/usr/bin/chmod 600 secret
/usr/bin/stat -c '%A' secret

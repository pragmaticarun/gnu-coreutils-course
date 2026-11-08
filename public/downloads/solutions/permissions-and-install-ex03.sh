#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (permissions-and-install).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'echo hi\n' > tool
/usr/bin/install -D -m 755 tool opt/bin/tool
/usr/bin/stat -c '%a' opt/bin/tool

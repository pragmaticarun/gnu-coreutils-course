#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (permissions-and-install).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf '#!/bin/sh\nprintf ok\n' > tool
/usr/bin/install -D -m 755 tool prefix/bin/tool
/usr/bin/stat -c '%a %n' prefix/bin/tool
before=$(/usr/bin/stat -c '%Y' prefix/bin/tool)
/usr/bin/install -C -m 755 tool prefix/bin/tool
after=$(/usr/bin/stat -c '%Y' prefix/bin/tool)
/usr/bin/printf 'mtime %s %s\n' "$before" "$after"

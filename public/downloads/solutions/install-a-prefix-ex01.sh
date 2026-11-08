#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (install-a-prefix).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/install -D -m 755 /usr/bin/true prefix/bin/true
/usr/bin/stat -c '%a' prefix/bin/true

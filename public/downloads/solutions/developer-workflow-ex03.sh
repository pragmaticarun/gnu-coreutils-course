#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (developer-workflow).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -u

cd "$(mktemp -d)"
/usr/bin/timeout 1 /usr/bin/sleep 3

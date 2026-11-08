#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (links).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -u

cd "$(mktemp -d)"
/usr/bin/mkdir dir
/usr/bin/unlink dir

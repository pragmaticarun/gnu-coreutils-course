#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (identity-and-host).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -u

cd "$(mktemp -d)"
/usr/bin/tty

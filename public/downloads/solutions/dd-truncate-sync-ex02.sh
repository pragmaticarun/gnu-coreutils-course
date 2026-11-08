#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (dd-truncate-sync).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/truncate -s 4096 h
/usr/bin/stat -c '%s %b' h

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (listing-with-ls).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/touch .env app
/usr/bin/ls -1 -A

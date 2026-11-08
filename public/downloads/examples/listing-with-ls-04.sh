#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (listing-with-ls).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/dir --version | /usr/bin/head -n 1
/usr/bin/vdir --version | /usr/bin/head -n 1
/usr/bin/dircolors -b | /usr/bin/head -n 2

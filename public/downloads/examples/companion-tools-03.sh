#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (companion-tools).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'a\nb\n' | /usr/bin/sed -n '2p'
/usr/bin/printf 'field:'
/usr/bin/printf 'a b\n' | /usr/bin/awk '{print $2}'
/usr/bin/awk -W version > awk-version.txt
/usr/bin/head -n 1 awk-version.txt

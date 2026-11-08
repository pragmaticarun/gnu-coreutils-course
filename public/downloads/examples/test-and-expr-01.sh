#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (test-and-expr).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
type test
type /usr/bin/test
/usr/bin/test -d /usr && /usr/bin/printf 'usr-is-dir\n'

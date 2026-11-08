#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (test-and-expr).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/test -d /tmp && /usr/bin/printf 'yes\n'

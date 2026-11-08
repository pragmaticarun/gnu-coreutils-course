#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (dd-truncate-sync).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'flushed-request\n' > note
/usr/bin/sync -f note
/usr/bin/printf 'sync-ok\n'

#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (dd-truncate-sync).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/dd if=/dev/zero of=z bs=512 count=1 status=none
/usr/bin/wc -c z

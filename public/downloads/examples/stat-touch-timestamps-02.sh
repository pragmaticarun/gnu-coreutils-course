#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (stat-touch-timestamps).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/touch -d '2020-01-02 03:04:05 UTC' stamped
/usr/bin/stat -c '%y' stamped

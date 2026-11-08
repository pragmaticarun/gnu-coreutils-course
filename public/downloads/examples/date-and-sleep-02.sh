#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (date-and-sleep).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/date -u -d '2020-01-02 + 1 day' '+%Y-%m-%d'

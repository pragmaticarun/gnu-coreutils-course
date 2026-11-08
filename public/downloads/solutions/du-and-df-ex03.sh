#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (du-and-df).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/df --output=source,fstype,target .

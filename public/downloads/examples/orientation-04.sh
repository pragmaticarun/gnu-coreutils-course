#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (orientation).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
dpkg -S /usr/bin/hostname
dpkg -S /usr/bin/kill
dpkg -S /usr/bin/uptime

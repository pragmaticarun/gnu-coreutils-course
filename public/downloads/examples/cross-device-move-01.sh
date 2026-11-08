#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (cross-device-move).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/printf 'payload\n' > local
dest="/dev/shm/cuwb-cb-$$"
trap 'rm -f "$dest"' EXIT
/usr/bin/stat -c 'src_dev=%d' .
/usr/bin/stat -c 'shm_dev=%d' /dev/shm
/usr/bin/mv local "$dest"
/usr/bin/cat "$dest"

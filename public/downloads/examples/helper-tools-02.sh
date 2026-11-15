#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (helper-tools).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf '%s\n' '{"items":[{"name":"libfoo","arch":"arm64"},{"name":"libbar","arch":"amd64"}]}' > api.json
/usr/bin/jq -r '.items[].name' api.json | LC_ALL=C /usr/bin/sort

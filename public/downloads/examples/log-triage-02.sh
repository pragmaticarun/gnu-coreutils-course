#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (log-triage).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/printf '%s\n' 'linker missing libfoo' 'linker missing libfoo' 'parser unexpected token' > errors.txt
LC_ALL=C /usr/bin/sort errors.txt | /usr/bin/uniq -c | /usr/bin/sed 's/^ *//'

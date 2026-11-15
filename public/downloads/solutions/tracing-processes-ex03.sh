#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (tracing-processes).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
if [ -x /usr/bin/perf ]; then /usr/bin/printf 'perf-present\n'; else /usr/bin/printf 'perf-absent\n'; fi

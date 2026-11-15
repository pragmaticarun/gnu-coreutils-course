#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (procps-processes).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/cp /usr/bin/sleep ./cuwbnap
./cuwbnap 5 &
nap=$!
/usr/bin/sleep 0.2
if /usr/bin/pgrep -x cuwbnap >/dev/null; then /usr/bin/printf 'found\n'; else /usr/bin/printf 'missing\n'; fi
/usr/bin/pkill -x cuwbnap
wait "$nap" || true
if /usr/bin/pgrep -x cuwbnap >/dev/null; then /usr/bin/printf 'still\n'; else /usr/bin/printf 'gone\n'; fi

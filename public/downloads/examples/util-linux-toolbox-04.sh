#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (util-linux-toolbox).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
/usr/bin/script -q -c '/usr/bin/printf "%s\n" payload-line' typescript >/dev/null
/usr/bin/tr -d '\r' < typescript | /usr/bin/grep -x payload-line
set +e
/usr/bin/logger --no-act -t cuwb 'hello-log' 2>logger.err
status=$?
set -e
/usr/bin/printf 'logger_status:%s\n' "$status"
/usr/bin/grep -F '/dev/log' logger.err
parent=$(/usr/bin/ps -o sid= -p $$ | /usr/bin/tr -d ' ')
child=$(/usr/bin/setsid /usr/bin/bash --noprofile --norc -c 'ps -o sid= -p $$' | /usr/bin/tr -d ' ')
if [ "$parent" != "$child" ]; then /usr/bin/printf 'new-session\n'; else /usr/bin/printf 'same-session\n'; fi
/usr/bin/prlimit --nofile=64 /usr/bin/bash --noprofile --norc -c 'ulimit -n'

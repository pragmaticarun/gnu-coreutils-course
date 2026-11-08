#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (developer-workflow).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir -p src
/usr/bin/printf '%s\n' 'int main(void) { return 0; }' > src/main.c
gcc -o src/app src/main.c
set +e
/usr/bin/timeout 2 src/app
/usr/bin/printf 'quick:%s\n' $?
/usr/bin/timeout 1 /usr/bin/sleep 3
/usr/bin/printf 'sleeper:%s\n' $?
set -e

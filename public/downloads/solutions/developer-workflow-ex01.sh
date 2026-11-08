#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (developer-workflow).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/mkdir -p src
/usr/bin/printf '%s\n' 'int main(void) { return 0; }' > src/main.c
gcc -o src/app src/main.c
/usr/bin/install -D -m 755 src/app dest/bin/app
/usr/bin/stat -c '%a' dest/bin/app

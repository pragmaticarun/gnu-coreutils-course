#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (paths).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
/usr/bin/basename /opt/ndk/libfoo.a .a
/usr/bin/dirname /opt/ndk/libfoo.a
/usr/bin/basename -a /a/b /c/d.txt

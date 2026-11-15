#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (atomic-publish).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf 'Refusing to run as root.\n' >&2
  exit 1
fi
cd "$(mktemp -d)"
mkdir -p out
umask 077
tmp=$(mktemp ./out/app-release.apk.XXXXXX)
printf 'finished-bytes\n' > "$tmp"
chmod 0644 "$tmp"
mv -f -- "$tmp" ./out/app-release.apk
stat -c '%a' out/app-release.apk

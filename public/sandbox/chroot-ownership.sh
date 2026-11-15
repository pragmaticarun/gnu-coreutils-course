#!/usr/bin/env bash
# Confirms /usr/sbin/chroot belongs to coreutils. Does not change the root.
set -euo pipefail
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then printf 'Refusing to run as root.\n' >&2; exit 1; fi
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
cd "$ROOT"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
owner=$(dpkg -S /usr/sbin/chroot)
[[ "$owner" == coreutils:* ]] || fail "owner $owner"
version=$(/usr/sbin/chroot --version | head -n 1)
[[ "$version" == chroot\ \(GNU\ coreutils\)* ]] || fail "version $version"
printf 'ok chroot-ownership\n'

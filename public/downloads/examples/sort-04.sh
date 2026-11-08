#!/usr/bin/env bash
# Example from the GNU Coreutils Workbench (sort).
# Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
set -eo pipefail

cd "$(mktemp -d)"
cat > comp << 'EOF'
#!/bin/sh
if [ "${1:-}" = "-d" ]; then cat; else cat; fi
printf 'x\n' >> "$COMPLOG"
EOF
chmod +x comp
export COMPLOG="$PWD/comp.log"
/usr/bin/seq 4000 | /usr/bin/sort -S 1K -T "$PWD" --compress-program="$PWD/comp" > /dev/null
/usr/bin/wc -l comp.log

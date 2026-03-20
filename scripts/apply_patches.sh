#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCHES="$ROOT/patches"
RECOVERED="$ROOT/recovered"

if [[ ! -d "$RECOVERED" ]] || [[ -z "$(find "$RECOVERED" -not -name ".gitkeep" -not -path "$RECOVERED" -print -quit)" ]]; then
    echo "Error: recovered/ is empty. Run scripts/decompile.sh first."
    exit 1
fi

APPLIED=0
FAILED=0

for patch_file in "$PATCHES"/*.patch; do
    [[ -e "$patch_file" ]] || continue
    patch_name="$(basename "$patch_file")"
    echo -n "Applying $patch_name ... "
    if patch -p0 -d "$ROOT" < "$patch_file"; then
        APPLIED=$((APPLIED + 1))
    else
        echo "FAILED"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "$APPLIED patch(es) applied successfully."
if [[ $FAILED -gt 0 ]]; then
    echo "$FAILED patch(es) failed. Check for .rej files in recovered/."
    exit 1
fi

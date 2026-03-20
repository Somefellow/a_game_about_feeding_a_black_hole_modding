#!/usr/bin/env bash
# Regenerates patches/ by diffing recovered/ against a fresh decompile of the original PCK.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINARY="$ROOT/tools/gdre_tools.x86_64"
ORIGINAL_PCK_DIR="$ROOT/original_pck"
RECOVERED="$ROOT/recovered"
PATCHES="$ROOT/patches"
TMPDIR="$ROOT/.tmp_decompile"

# Check binary exists
if [[ ! -x "$BINARY" ]]; then
    echo "Error: $BINARY not found. Run scripts/init.sh first."
    exit 1
fi

# Find .pck file
mapfile -t PCKS < <(find "$ORIGINAL_PCK_DIR" -maxdepth 1 -name "*.pck")
if [[ ${#PCKS[@]} -eq 0 ]]; then
    echo "Error: No .pck file found in original_pck/."
    exit 1
fi
if [[ ${#PCKS[@]} -gt 1 ]]; then
    echo "Error: Multiple .pck files found in original_pck/."
    exit 1
fi
PCK="${PCKS[0]}"
echo "Using PCK: $PCK"

# Decompile original into temp dir
echo "Decompiling original PCK for baseline..."
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"
"$BINARY" --headless --recover="$PCK" --output="$TMPDIR" 2>&1

# Find all .gd files that differ between recovered/ and the baseline
echo "Scanning for changed .gd files..."
mkdir -p "$PATCHES"
UPDATED=0
REMOVED=0

# Remove patches for files that are no longer changed
for patch_file in "$PATCHES"/*.patch; do
    [[ -e "$patch_file" ]] || continue
    patch_name="$(basename "$patch_file" .patch)"
    # Reverse the naming: __ → / and _ → space
    rel_path="${patch_name//__//}"
    rel_path="${rel_path//_/ }"
    if [[ -f "$RECOVERED/$rel_path" ]] && diff -q "$RECOVERED/$rel_path" "$TMPDIR/$rel_path" > /dev/null 2>&1; then
        echo "  [no longer changed, removing] $rel_path"
        rm "$patch_file"
        REMOVED=$((REMOVED + 1))
    fi
done

# Generate/update patches for changed files
while IFS= read -r -d '' GD_FILE; do
    # Skip .autoconverted/ files
    if [[ "$GD_FILE" == *"/.autoconverted/"* ]]; then
        continue
    fi

    REL="${GD_FILE#$RECOVERED/}"
    ORIG="$TMPDIR/$REL"

    # Skip files that don't exist in the original (new files handled separately)
    if [[ ! -f "$ORIG" ]]; then
        echo "  [new file, skipping] $REL"
        continue
    fi

    if ! diff -q "$GD_FILE" "$ORIG" > /dev/null 2>&1; then
        patch_name="${REL// /_}"
        patch_name="${patch_name//\//__}"
        patch_file="$PATCHES/${patch_name}.patch"

        diff -u "$ORIG" "$GD_FILE" \
            --label "recovered/$REL" \
            --label "recovered/$REL" \
            > "$patch_file" || true

        echo "  [updated] patches/${patch_name}.patch"
        UPDATED=$((UPDATED + 1))
    fi
done < <(find "$RECOVERED" -name "*.gd" -print0)

rm -rf "$TMPDIR"

echo ""
echo "$UPDATED patch(es) updated, $REMOVED removed."

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINARY="$ROOT/tools/gdre_tools.x86_64"
ORIGINAL_PCK_DIR="$ROOT/original_pck"
RECOVERED="$ROOT/recovered"
COMPILED="$ROOT/compiled"
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
PCK_BASENAME="$(basename "$PCK" .pck)"
echo "Using PCK: $PCK"

# Decompile original into temp dir to detect bytecode revision and get baseline
echo "Decompiling original PCK into temp dir for diff baseline..."
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"

RECOVER_OUTPUT=$("$BINARY" --headless --recover="$PCK" --output="$TMPDIR" 2>&1 || true)
echo "$RECOVER_OUTPUT"

# Parse bytecode revision
BYTECODE=$(echo "$RECOVER_OUTPUT" | grep -i "bytecode revision" | grep -oP '\([0-9a-f]+\)' | tr -d '()' | head -1)
if [[ -z "$BYTECODE" ]]; then
    echo "Error: Could not detect bytecode revision from gdre_tools output."
    echo "Output was:"
    echo "$RECOVER_OUTPUT"
    rm -rf "$TMPDIR"
    exit 1
fi
echo "Detected bytecode revision: $BYTECODE"

# Find changed/new .gd files in recovered/
echo "Scanning for changed .gd files..."
PATCH_ARGS=()
CHANGED_COUNT=0

while IFS= read -r -d '' GD_FILE; do
    # Skip .autoconverted/ files
    if [[ "$GD_FILE" == *"/.autoconverted/"* ]]; then
        continue
    fi

    REL="${GD_FILE#$RECOVERED/}"
    ORIG="$TMPDIR/$REL"

    if [[ ! -f "$ORIG" ]]; then
        echo "  [new]     $REL"
        CHANGED=true
    elif ! diff -q "$GD_FILE" "$ORIG" > /dev/null 2>&1; then
        echo "  [changed] $REL"
        CHANGED=true
    else
        CHANGED=false
    fi

    if [[ "$CHANGED" == true ]]; then
        # Compile the .gd file
        "$BINARY" --headless \
            --compile="$GD_FILE" \
            --bytecode="$BYTECODE" \
            --output="$COMPILED"

        GD_BASENAME="$(basename "$GD_FILE" .gd)"
        GDC_FILE="$COMPILED/${GD_BASENAME}.gdc"
        REL_GDC="${REL%.gd}.gdc"

        PATCH_ARGS+=("--patch-file=${GDC_FILE}=res://${REL_GDC}")
        CHANGED_COUNT=$((CHANGED_COUNT + 1))
    fi
done < <(find "$RECOVERED" -name "*.gd" -print0)

if [[ $CHANGED_COUNT -eq 0 ]]; then
    echo "No changes detected. Nothing to recompile."
    rm -rf "$TMPDIR"
    exit 0
fi

echo "$CHANGED_COUNT file(s) changed. Running pck-patch..."

mkdir -p "$ROOT/modded_pck"
OUTPUT_PCK="$ROOT/modded_pck/${PCK_BASENAME}.pck"
"$BINARY" --headless \
    --pck-patch="$PCK" \
    "${PATCH_ARGS[@]}" \
    --output="$OUTPUT_PCK"

rm -rf "$TMPDIR"

echo "Done! Modded PCK written to: $OUTPUT_PCK"

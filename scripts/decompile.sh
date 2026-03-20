#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINARY="$ROOT/tools/gdre_tools.x86_64"
ORIGINAL_PCK_DIR="$ROOT/original_pck"
RECOVERED="$ROOT/recovered"

# Check binary exists
if [[ ! -x "$BINARY" ]]; then
    echo "Error: $BINARY not found. Run scripts/init.sh first."
    exit 1
fi

# Find .pck file
mapfile -t PCKS < <(find "$ORIGINAL_PCK_DIR" -maxdepth 1 -name "*.pck")
if [[ ${#PCKS[@]} -eq 0 ]]; then
    echo "Error: No .pck file found in original_pck/. Drop your game's .pck there first."
    exit 1
fi
if [[ ${#PCKS[@]} -gt 1 ]]; then
    echo "Error: Multiple .pck files found in original_pck/. Please keep only one."
    exit 1
fi
PCK="${PCKS[0]}"
echo "Found PCK: $PCK"

# Warn if recovered/ is non-empty (ignoring .gitkeep)
EXISTING=$(find "$RECOVERED" -not -name ".gitkeep" -not -path "$RECOVERED" -print -quit)
if [[ -n "$EXISTING" ]]; then
    read -r -p "Warning: recovered/ is non-empty. Overwrite? [y/N] " answer || true
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo "Decompiling $PCK into recovered/..."
"$BINARY" --headless --recover="$PCK" --output="$RECOVERED"

echo "Done. Decompiled source is in: $RECOVERED"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$ROOT/tools"
ZIP="$TOOLS/gdre_tools.zip"
BINARY="$TOOLS/gdre_tools.x86_64"
URL="https://github.com/GDRETools/gdsdecomp/releases/download/v2.4.0/GDRE_tools-v2.4.0-linux.zip"

echo "Downloading GDRETools v2.4.0..."
curl -L -o "$ZIP" "$URL"

echo "Unzipping into tools/..."
unzip -o "$ZIP" -d "$TOOLS"

chmod +x "$BINARY"

echo "Done. GDRETools is ready at: $BINARY"

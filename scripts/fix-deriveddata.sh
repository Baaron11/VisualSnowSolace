#!/usr/bin/env bash
# fix-deriveddata.sh — Fixes Xcode DerivedData permission errors for Visual Snow Solace
#
# Usage:  ./scripts/fix-deriveddata.sh
#
# This resolves the "Xcode can't write to DerivedData" build error,
# which is a file-permissions issue (not a missing plist entry).

set -euo pipefail

DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
PROJECT_PREFIX="Visual_Snow_Solace-"

echo "=== Visual Snow Solace — DerivedData Fix ==="
echo ""

# 1. Remove the project-specific DerivedData cache
matching_dirs=()
if [ -d "$DERIVED_DATA" ]; then
    while IFS= read -r -d '' dir; do
        matching_dirs+=("$dir")
    done < <(find "$DERIVED_DATA" -maxdepth 1 -type d -name "${PROJECT_PREFIX}*" -print0 2>/dev/null)
fi

if [ ${#matching_dirs[@]} -gt 0 ]; then
    for dir in "${matching_dirs[@]}"; do
        echo "Removing: $dir"
        rm -rf "$dir"
    done
    echo "Cleared project DerivedData cache."
else
    echo "No existing DerivedData cache found for Visual Snow Solace."
fi

# 2. Fix ownership of the DerivedData folder itself
if [ -d "$DERIVED_DATA" ]; then
    current_owner=$(stat -f '%Su' "$DERIVED_DATA" 2>/dev/null || stat -c '%U' "$DERIVED_DATA" 2>/dev/null)
    if [ "$current_owner" != "$(whoami)" ]; then
        echo ""
        echo "DerivedData folder is owned by '$current_owner' instead of '$(whoami)'."
        echo "Fixing ownership (may require your password)..."
        sudo chown -R "$(whoami)" "$DERIVED_DATA"
        echo "Ownership fixed."
    else
        echo "DerivedData ownership is correct ($(whoami))."
    fi
else
    echo "DerivedData folder does not exist yet — Xcode will create it on next build."
fi

echo ""
echo "Done. Next steps:"
echo "  1. Open the project in Xcode"
echo "  2. Product -> Clean Build Folder (Shift+Cmd+K)"
echo "  3. Build again (Cmd+B)"
echo ""
echo "If the error recurs, check permissions with:"
echo "  ls -la ~/Library/Developer/Xcode/DerivedData/"

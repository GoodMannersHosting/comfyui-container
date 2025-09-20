#!/bin/bash

# PVC Permission Fix Script
# Usage: kubectl exec -it <pod-name> -- /app/ComfyUI/scripts/fix-permissions.sh

echo "=== ComfyUI PVC Permission Fix ==="
echo "This script will attempt to fix ownership issues with PVCs"
echo "It should be run as root or with sudo privileges"
echo

# Check if running as root or if sudo is available
if [ "$EUID" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        echo "Running with sudo..."
        SUDO="sudo"
    else
        echo "ERROR: This script needs to be run as root or with sudo privileges"
        echo "Try: kubectl exec -it <pod-name> -- sudo /app/ComfyUI/scripts/fix-permissions.sh"
        exit 1
    fi
else
    SUDO=""
fi

echo "Fixing ownership for ComfyUI directories..."

# Fix ownership of main directories
directories=(
    "/app/venv"
    "/app/ComfyUI/custom_nodes"
    "/app/ComfyUI/models"
    "/app/ComfyUI/output"
    "/app/ComfyUI/user"
)

for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        echo "Fixing ownership for: $dir"
        $SUDO chown -R 1001:1001 "$dir"
        $SUDO chmod -R u+w "$dir"
        echo "  ✓ Fixed: $dir"
    else
        echo "  ⚠ Not found: $dir"
    fi
done

echo
echo "=== Permission Fix Complete ==="
echo "You can now restart the pod or run the upgrade manually:"
echo "  kubectl exec -it <pod-name> -- /app/ComfyUI/scripts/force-upgrade.sh"
echo
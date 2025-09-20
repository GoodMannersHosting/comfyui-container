#!/bin/bash

# Manual upgrade trigger script
# Usage: kubectl exec -it <pod-name> -- /app/ComfyUI/scripts/force-upgrade.sh

echo "=== FORCING ComfyUI UPGRADE ==="
echo "This will update ComfyUI Manager and virtual environment packages"
echo "regardless of version tracking."
echo

read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Upgrade cancelled."
    exit 0
fi

# Remove version tracking files to force upgrade
echo "Removing version tracking files..."
rm -f /app/ComfyUI/custom_nodes/.pvc_version
rm -f /app/ComfyUI/custom_nodes/.pvc_build_date
rm -f /app/venv/.venv_version

# Run the upgrade check script
echo "Running upgrade process..."
if [ -f "/app/ComfyUI/scripts/upgrade-check.sh" ]; then
    bash /app/ComfyUI/scripts/upgrade-check.sh
    if [ $? -eq 0 ]; then
        echo "=== MANUAL UPGRADE COMPLETED SUCCESSFULLY ==="
    else
        echo "=== MANUAL UPGRADE FAILED ==="
        exit 1
    fi
else
    echo "ERROR: Upgrade check script not found"
    exit 1
fi
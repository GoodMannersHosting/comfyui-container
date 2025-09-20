#!/bin/bash

# Run upgrade check and handle any necessary updates
echo "Checking for ComfyUI upgrades..."
if [ -f "/app/ComfyUI/scripts/upgrade-check.sh" ]; then
    bash /app/ComfyUI/scripts/upgrade-check.sh
    if [ $? -ne 0 ]; then
        echo "ERROR: Upgrade process failed"
        exit 1
    fi
else
    echo "Upgrade check script not found - performing basic setup..."
    
    # Fallback: Copy ComfyUI Manager if it doesn't exist
    if [ ! -d "/app/ComfyUI/custom_nodes/comfyui-manager" ]; then
        echo "Installing ComfyUI Manager..."
        cp -r /app/comfyui-manager /app/ComfyUI/custom_nodes/comfyui-manager || \
            echo "ERROR: Failed to copy ComfyUI Manager"
    fi
fi

echo "Starting ComfyUI..."

# Run the ComfyUI entrypoint script
/app/venv/bin/python -u main.py \
    --front-end-version Comfy-Org/ComfyUI_frontend@latest \
    --listen 0.0.0.0  ${CLI_ARGS}

#!/bin/bash

# Check and potentially restore virtual environment health
if [ -f "/app/scripts/venv-check.sh" ]; then
    echo "Running virtual environment health check..."
    bash /app/scripts/venv-check.sh
else
    # Fallback to simple check if health check script not available
    if [ ! -f "/app/venv/bin/python" ]; then
        echo "Initializing virtual environment from backup..."
        cp -r /app/venv-backup/* /app/venv/
        echo "Virtual environment initialized successfully"
    else
        echo "Using existing virtual environment"
    fi
fi

# Copy the ComfyUI Manager to the custom_nodes directory
cp -r /app/comfyui-manager \
    /app/ComfyUI/custom_nodes/comfyui-manager || \
    echo "ERROR: Failed to copy ComfyUI Manager"

# Run the ComfyUI entrypoint script
python3 -u main.py \
    --front-end-version Comfy-Org/ComfyUI_frontend@latest \
    --listen 0.0.0.0  ${CLI_ARGS}

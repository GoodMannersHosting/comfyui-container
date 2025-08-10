#!/bin/bash

# Copy the ComfyUI Manager to the custom_nodes directory
cp -r /app/comfyui-manager \
    /app/ComfyUI/custom_nodes/comfyui-manager || \
    echo "ERROR: Failed to copy ComfyUI Manager"

# Run the ComfyUI entrypoint script
python3 -u main.py \
    --front-end-version Comfy-Org/ComfyUI_frontend@latest \
    --listen 0.0.0.0  ${CLI_ARGS}

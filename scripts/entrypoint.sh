#!/bin/bash

# Move the ComfyUI Manager to the custom_nodes directory
mv -r /app/comfyui-manager \
    /app/ComfyUI/custom_nodes/comfyui-manager || \
    echo "ERROR: Failed to move ComfyUI Manager" && exit 1

# Use the virtual environment's Python interpreter
venv/bin/python3 \
    -u main.py --listen 0.0.0.0 \
    --front-end-version Comfy-Org/ComfyUI_frontend@latest \
    /app/ComfyUI/scripts/entrypoint.py ${CLI_ARGS}

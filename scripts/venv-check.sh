#!/bin/bash

# Virtual Environment Health Check and Recovery Script

VENV_PATH="/app/venv"
BACKUP_PATH="/app/venv-backup"
CONTAINER_PYPROJECT="/app/ComfyUI/comfyui_version.py"
VOLUME_PYPROJECT="/app/venv/comfyui_version.py"

get_version() {
    local version_file="$1"
    if [ -f "$version_file" ]; then
        # Extract version from comfyui_version.py using grep and awk
        local version=$(cat "$version_file" | grep -E '.*version.*' | awk '{print $3}' | tr -d '"' | tr -d "'")
        echo "$version"
    else
        echo ""
    fi
}

check_version_mismatch() {
    local container_version=$(get_version "$CONTAINER_PYPROJECT")
    local volume_version=$(get_version "$VOLUME_PYPROJECT")
    
    echo "Container ComfyUI version: ${container_version:-'unknown'}"
    echo "Volume ComfyUI version: ${volume_version:-'none'}"
    
    if [ -z "$container_version" ]; then
        echo "WARNING: Could not determine container ComfyUI version"
        return 1
    fi
    
    if [ -z "$volume_version" ]; then
        echo "INFO: No version found in volume, will restore from source"
        return 0
    fi
    
    if [ "$container_version" != "$volume_version" ]; then
        echo "VERSION MISMATCH: Container version: $container_version, Volume version: $volume_version"
        echo "Restoring virtual environment to match container version..."
        return 0
    fi
    
    echo "Version match: $container_version"
    return 1
}

check_venv_health() {
    local venv_python="$VENV_PATH/bin/python"
    
    # Check if virtual environment exists and is accessible
    if [ ! -f "$venv_python" ]; then
        echo "ERROR: Virtual environment Python executable not found"
        return 1
    fi
    
    echo "Virtual environment appears healthy"
    return 0
}

restore_venv() {
    echo "Restoring virtual environment from source..."
    
    # Remove corrupted venv
    rm -rf "$VENV_PATH"/*
    
    # Copy from source
    cp -r "$source_PATH"/* "$VENV_PATH/"
    
    # Verify restoration
    if check_venv_health; then
        echo "Virtual environment restored successfully"
        return 0
    else
        echo "ERROR: Failed to restore virtual environment"
        return 1
    fi
}

# Main execution
echo "Checking virtual environment health and version compatibility..."

# First check for version mismatch
if check_version_mismatch; then
    echo "Version mismatch detected, restoring virtual environment from source..."
    restore_venv
    exit $?
fi

# If versions match, check health
case $(check_venv_health) in
    0)
        echo "Virtual environment matches source, no action needed"
        exit 0
        ;;
    1)
        echo "Virtual environment does not match, restoring from source..."
        restore_venv
        exit $?
        ;;
    *)
        echo "Unknown error checking virtual environment"
        exit 1
        ;;
esac

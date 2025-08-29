#!/bin/bash

# Virtual Environment Health Check and Recovery Script

VENV_PATH="/app/venv"
BACKUP_PATH="/app/venv-backup"
REQUIRED_PACKAGES=("torch" "torchvision" "torchaudio" "numpy" "pillow")
CONTAINER_PYPROJECT="/app/ComfyUI/pyproject.toml"
VOLUME_PYPROJECT="/app/venv/pyproject.toml"

get_version_from_pyproject() {
    local pyproject_file="$1"
    if [ -f "$pyproject_file" ]; then
        # Extract version from pyproject.toml using grep and sed
        local version=$(grep -E '^version\s*=' "$pyproject_file" | sed 's/version\s*=\s*"\([^"]*\)"/\1/' | tr -d ' ')
        echo "$version"
    else
        echo ""
    fi
}

check_version_mismatch() {
    local container_version=$(get_version_from_pyproject "$CONTAINER_PYPROJECT")
    local volume_version=$(get_version_from_pyproject "$VOLUME_PYPROJECT")
    
    echo "Container ComfyUI version: ${container_version:-'unknown'}"
    echo "Volume ComfyUI version: ${volume_version:-'none'}"
    
    if [ -z "$container_version" ]; then
        echo "WARNING: Could not determine container ComfyUI version"
        return 1
    fi
    
    if [ -z "$volume_version" ]; then
        echo "INFO: No version found in volume, will restore from backup"
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
    local site_packages="$VENV_PATH/lib/python3.12/site-packages"
    
    # Check if virtual environment exists and is accessible
    if [ ! -f "$venv_python" ]; then
        echo "ERROR: Virtual environment Python executable not found"
        return 1
    fi
    
    if [ ! -d "$site_packages" ]; then
        echo "ERROR: Site-packages directory not found"
        return 1
    fi
    
    # Test if Python can import basic packages
    if ! "$venv_python" -c "import sys; print('Python version:', sys.version)" >/dev/null 2>&1; then
        echo "ERROR: Virtual environment Python is not functional"
        return 1
    fi
    
    # Check for critical packages
    local missing_packages=()
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! "$venv_python" -c "import $package" >/dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo "WARNING: Missing critical packages: ${missing_packages[*]}"
        return 2
    fi
    
    echo "Virtual environment appears healthy"
    return 0
}

restore_venv() {
    echo "Restoring virtual environment from backup..."
    
    # Remove corrupted venv
    rm -rf "$VENV_PATH"/*
    
    # Copy from backup
    cp -r "$BACKUP_PATH"/* "$VENV_PATH/"
    
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
    echo "Version mismatch detected, restoring virtual environment from backup..."
    restore_venv
    exit $?
fi

# If versions match, check health
case $(check_venv_health) in
    0)
        echo "Virtual environment is healthy and version-compatible, no action needed"
        exit 0
        ;;
    1)
        echo "Virtual environment is severely damaged, restoring from backup..."
        restore_venv
        exit $?
        ;;
    2)
        echo "Virtual environment has missing packages, attempting repair..."
        # Try to install missing packages without full restore
        if ! restore_venv; then
            echo "Repair failed, performing full restoration"
            restore_venv
        fi
        exit $?
        ;;
    *)
        echo "Unknown error checking virtual environment"
        exit 1
        ;;
esac

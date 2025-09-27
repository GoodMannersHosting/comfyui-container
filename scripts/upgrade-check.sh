#!/bin/bash

# ComfyUI Upgrade Detection and Handling Script

# Paths
CONTAINER_VERSION_FILE="/app/ComfyUI/.container_version"
CONTAINER_BUILD_DATE_FILE="/app/ComfyUI/.container_build_date"
PVC_VERSION_FILE="/app/ComfyUI/custom_nodes/.pvc_version"
PVC_BUILD_DATE_FILE="/app/ComfyUI/custom_nodes/.pvc_build_date"
VENV_VERSION_FILE="/app/venv/.venv_version"

get_container_version() {
    if [ -f "$CONTAINER_VERSION_FILE" ]; then
        cat "$CONTAINER_VERSION_FILE"
    else
        echo "unknown"
    fi
}

get_container_build_date() {
    if [ -f "$CONTAINER_BUILD_DATE_FILE" ]; then
        cat "$CONTAINER_BUILD_DATE_FILE"
    else
        echo "unknown"
    fi
}

get_pvc_version() {
    if [ -f "$PVC_VERSION_FILE" ]; then
        cat "$PVC_VERSION_FILE"
    else
        echo "none"
    fi
}

get_pvc_build_date() {
    if [ -f "$PVC_BUILD_DATE_FILE" ]; then
        cat "$PVC_BUILD_DATE_FILE"
    else
        echo "none"
    fi
}

is_upgrade_needed() {
    local container_version=$(get_container_version)
    local pvc_version=$(get_pvc_version)
    local container_build_date=$(get_container_build_date)
    local pvc_build_date=$(get_pvc_build_date)
    
    echo "Container version: $container_version (built: $container_build_date)"
    echo "PVC version: $pvc_version (built: $pvc_build_date)"
    
    # If no PVC version exists, this is first run
    if [ "$pvc_version" = "none" ]; then
        echo "First run detected - will initialize PVCs"
        return 0
    fi
    
    # If versions differ, upgrade needed
    if [ "$container_version" != "$pvc_version" ]; then
        echo "Version mismatch detected - upgrade needed"
        echo "  Container: $container_version"
        echo "  PVC: $pvc_version"
        return 0
    fi
    
    # If build dates differ (same version, different build), upgrade needed
    if [ "$container_build_date" != "$pvc_build_date" ]; then
        echo "Build date mismatch detected - upgrade needed"
        echo "  Container: $container_build_date"
        echo "  PVC: $pvc_build_date"
        return 0
    fi
    
    echo "No upgrade needed - versions and build dates match"
    return 1
}

update_comfyui_manager() {
    echo "Updating ComfyUI Manager..."
    
    # Check if old manager exists
    if [ -d "/app/ComfyUI/custom_nodes/comfyui-manager" ]; then
        echo "Found existing ComfyUI Manager - attempting to update..."
        
        # Try to remove old manager, but handle permission issues gracefully
        if ! rm -rf /app/ComfyUI/custom_nodes/comfyui-manager 2>/dev/null; then
            echo "Cannot remove old ComfyUI Manager due to permissions - trying alternative approach..."
            
            # Create a new directory name
            local backup_name="comfyui-manager-old-$(date +%s)"
            if mv "/app/ComfyUI/custom_nodes/comfyui-manager" "/app/ComfyUI/custom_nodes/$backup_name" 2>/dev/null; then
                echo "Moved old manager to $backup_name"
            else
                echo "WARNING: Cannot remove or move old ComfyUI Manager due to permission restrictions"
                echo "This may be due to PVC ownership issues. The upgrade will install alongside the old version."
                echo "Consider manually cleaning up old versions from the custom_nodes PVC."
                
                # Use a different name for the new installation
                local install_path="/app/ComfyUI/custom_nodes/comfyui-manager-new"
                echo "Installing new ComfyUI Manager to: $install_path"
                
                if cp -r /app/comfyui-manager "$install_path" 2>/dev/null; then
                    echo "New ComfyUI Manager installed successfully at $install_path"
                    return 0
                else
                    echo "ERROR: Failed to install new ComfyUI Manager"
                    return 1
                fi
            fi
        else
            echo "Successfully removed old ComfyUI Manager"
        fi
    fi
    
    # Install new manager to standard location
    echo "Installing new ComfyUI Manager..."
    if cp -r /app/comfyui-manager /app/ComfyUI/custom_nodes/comfyui-manager 2>/dev/null; then
        echo "ComfyUI Manager updated successfully"
        return 0
    else
        echo "ERROR: Failed to install ComfyUI Manager - check PVC permissions"
        echo "PVC may be owned by different user/group. Consider:"
        echo "1. kubectl exec into pod and run: chown -R 1001:1001 /app/ComfyUI/custom_nodes"
        echo "2. Or delete the custom_nodes PVC and let it recreate with proper ownership"
        return 1
    fi
}

update_venv() {
    echo "Updating virtual environment..."
    
    # Check if venv exists and has packages
    if [ -d "/app/venv/lib" ] && [ "$(ls -A /app/venv/lib 2>/dev/null)" ]; then
        echo "Existing venv found with packages - upgrading in place..."
        
        # Check if we can write to venv
        if [ ! -w "/app/venv" ]; then
            echo "WARNING: Cannot write to /app/venv - check PVC permissions"
            echo "Virtual environment updates may fail. Consider:"
            echo "1. kubectl exec into pod and run: chown -R 1001:1001 /app/venv"
            echo "2. Or delete the venv PVC and let it recreate"
            echo "Attempting upgrade anyway..."
        fi
        
        # Update core packages that might have version conflicts
        echo "Upgrading PyTorch packages..."
        if ! uv pip install --upgrade \
            torch torchvision torchaudio \
            --extra-index-url https://download.pytorch.org/whl/cu128 2>/dev/null; then
            echo "WARNING: Failed to upgrade PyTorch packages - may be permission issues"
        fi
        
        # Reinstall ComfyUI requirements to ensure compatibility
        if [ -f "/app/ComfyUI/requirements.txt" ]; then
            echo "Upgrading ComfyUI requirements..."
            if ! uv pip install -r /app/ComfyUI/requirements.txt --upgrade 2>/dev/null; then
                echo "WARNING: Failed to upgrade ComfyUI requirements - may be permission issues"
            fi
        fi
        
        # Reinstall ComfyUI Manager requirements
        if [ -f "/app/comfyui-manager/requirements.txt" ]; then
            echo "Upgrading ComfyUI Manager requirements..."
            if ! uv pip install -r /app/comfyui-manager/requirements.txt --upgrade 2>/dev/null; then
                echo "WARNING: Failed to upgrade ComfyUI Manager requirements - may be permission issues"
            fi
        fi
    else
        echo "No existing venv found or venv is empty"
        echo "This is normal on first run - using venv from container image"
        
        # Ensure venv directory exists
        mkdir -p /app/venv 2>/dev/null || true
        
        # Check if we can use the venv from the container
        if [ -f "/app/venv/bin/python" ]; then
            echo "Using venv from container image"
        else
            echo "ERROR: No functional virtual environment available"
            return 1
        fi
    fi
    
    # Mark venv version (if we can write to it)
    if echo "$(get_container_version)" > "$VENV_VERSION_FILE" 2>/dev/null; then
        echo "Virtual environment updated successfully"
    else
        echo "WARNING: Cannot write version file - venv PVC may have permission issues"
        echo "Virtual environment update completed with warnings"
    fi
    
    return 0
}

mark_upgrade_complete() {
    local container_version=$(get_container_version)
    local container_build_date=$(get_container_build_date)
    
    # Create directories if they don't exist
    mkdir -p "$(dirname "$PVC_VERSION_FILE")"
    mkdir -p "$(dirname "$VENV_VERSION_FILE")"
    
    # Mark PVC with current versions
    echo "$container_version" > "$PVC_VERSION_FILE"
    echo "$container_build_date" > "$PVC_BUILD_DATE_FILE"
    echo "$container_version" > "$VENV_VERSION_FILE"
    
    echo "Upgrade complete - PVCs marked with version $container_version"
}

# Main upgrade process
perform_upgrade() {
    echo "=== Starting ComfyUI Upgrade Process ==="
    
    # Update ComfyUI Manager
    if ! update_comfyui_manager; then
        echo "ERROR: ComfyUI Manager update failed"
        return 1
    fi
    
    # Update virtual environment
    if ! update_venv; then
        echo "ERROR: Virtual environment update failed"
        return 1
    fi
    
    # Mark upgrade as complete
    mark_upgrade_complete
    
    echo "=== Upgrade Process Complete ==="
    return 0
}

# Check if upgrade is needed and perform if necessary
if is_upgrade_needed; then
    perform_upgrade
    exit $?
else
    echo "No upgrade needed - starting ComfyUI with current configuration"
    exit 0
fi
# ComfyUI Docker Container

A production-ready Docker container for [ComfyUI](https://github.com/comfyanonymous/ComfyUI) optimized for RTX 50X0 and Blackwell GPUs, featuring stateful Python package management with `uv` and virtual environments.

## Features

- **GPU Optimized**: Built for RTX 50X0 and Blackwell GPUs with CUDA support.
- **Stateful Package Management**: Uses `uv` with persistent virtual environments for runtime package installation.
- **Kubernetes Ready**: Designed for stateful deployments with persistent storage.
- **Automatic Recovery**: Smart virtual environment health checking and version-based restoration.

## Container Architecture

### Python Environment

- **Base**: Ubuntu 24.04 with Python 3.12.
- **Package Manager**: [uv](https://github.com/astral-sh/uv) for fast, reliable Python package management.
- **Virtual Environment**: Isolated `/app/venv` with persistent storage support.
- **Package Persistence**: User-installed packages via `uv add` persist across container restarts.

### Key Components

- **ComfyUI**: Latest version with configurable branch/tag support.
- **ComfyUI Manager**: Built-in custom node manager for easy extensions.
- **PyTorch**: CUDA-enabled PyTorch with configurable CUDA versions.
- **Health Monitoring**: Intelligent virtual environment validation and recovery.

## Kubernetes Deployment

This container is designed to work with the [BJW-S App-Template](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/library/common) Helm chart for production deployments.

### Production Deployment Files

The production Kubernetes deployment configuration can be found in the [home-enterprise-labops](https://github.com/danmanners/home-enterprise-labops) repository:

- **Helm Values**: [`kubernetes/services/comfyui/values.yaml`](https://github.com/danmanners/home-enterprise-labops/tree/main/kubernetes/services/comfyui/values.yaml)
- **ArgoCD Configuration**: Managed through ArgoCD; [find my current Argo Application file here](https://github.com/GoodMannersHosting/home-enterprise-labops/blob/main/kubernetes/applications/comfyui.yaml).

### Key Kubernetes Features

- **Persistent Storage**: Models, output, workflows, and custom nodes.
- **Virtual Environment Persistence**: Python packages survive pod restarts.
- **GPU Support**: NVIDIA GPU allocation and management.
- **Resource Management**: Configurable CPU, memory, and GPU limits.
- **File Browser**: Integrated file browser for easy model and output management.

### Storage Volumes

| Volume          | Purpose                       | Size  | Persistence |
| --------------- | ----------------------------- | ----- | ----------- |
| `models`        | AI models and checkpoints     | 400Gi | Retained    |
| `output`        | Generated images and outputs  | 40Gi  | Retained    |
| `workflows`     | Saved workflow configurations | 4Gi   | Retained    |
| `custom-nodes`  | Custom ComfyUI nodes          | 4Gi   | Retained    |
| `venv`          | Python virtual environment    | 2Gi   | Retained    |
| `user-packages` | uv cache and user packages    | 5Gi   | Retained    |

## Stateful Package Management

### How It Works

1. **Initial Build**: Container creates virtual environment with ComfyUI requirements.
2. **Persistent Storage**: Virtual environment mounted to persistent volume.
3. **Health Checking**: Automatic validation of virtual environment integrity.
4. **Version Management**: Compares ComfyUI versions to determine restoration needs.
5. **Package Persistence**: User-installed packages survive container restarts.

### Using uv Commands

Once deployed, you can manage Python packages directly in the container or through the ComfyUI Manager.

### Automatic Recovery

The container automatically handles:

- **First Run**: Initializes virtual environment from backup
- **Version Mismatches**: Restores when ComfyUI versions differ
- **Corruption**: Recovers damaged virtual environments
- **Health Validation**: Ensures all critical packages are functional

## Development and Customization

### Adding Custom Nodes

Custom nodes can be added by:

1. Installing via ComfyUI Manager in the web interface.
2. Using `uv add` for Python packages.
3. Adding to the `custom-nodes` persistent volume.

### Modifying Requirements

To add new base requirements:

1. Update the containerfile
2. Rebuild the image
3. Deploy with ArgoCD (automatic virtual environment restoration)

### Environment Variables

| Variable                 | Purpose                  | Default              |
| ------------------------ | ------------------------ | -------------------- |
| `VIRTUAL_ENV`            | Virtual environment path | `/app/venv`          |
| `UV_PROJECT_ENVIRONMENT` | uv project environment   | `/app/venv`          |
| `UV_CACHE_DIR`           | uv cache directory       | `/app/user-packages` |
| `NVIDIA_VISIBLE_DEVICES` | GPU visibility           | `all`                |
| `CLI_ARGS`               | ComfyUI CLI arguments    | `--verbose=DEBUG`    |

## Monitoring and Troubleshooting

### Health Checks

The container includes comprehensive health monitoring:

- Virtual environment integrity validation
- Critical package availability checking
- Version compatibility verification
- Automatic recovery procedures

### Logs

Key log messages to monitor:

- Virtual environment initialization
- Version mismatch detection
- Package installation status
- Recovery procedure results

### Common Issues

1. **Virtual Environment Corruption**: Automatically restored from backup
2. **Version Mismatches**: Handled by automatic restoration
3. **Missing Packages**: Detected and reported for manual intervention
4. **Storage Issues**: Persistent volumes ensure data survival

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with local builds
5. Submit a pull request

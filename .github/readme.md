# ComfyUI Docker Container

Containerfile for ComfyUI that works for RTX 50X0 and Blackwell GPUs.

## Build it yourself locally

```bash
podman build \
    --platform linux/amd64 \
    --layers=true \
    --squash \
    -t $ContainerRegistry/$Repository/comfyui:v0.3.45 \
    -f containerfile .
```

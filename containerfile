ARG VERSION="v0.3.45"
FROM harbor.cloud.danmanners.com/library/nvidia/cuda:12.9.1-cudnn-runtime-ubuntu24.04 as build
LABEL maintainer="daniel.a.manners@gmail.com"
LABEL build_date="2025-07-20"
ARG VERSION

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    python3.12 \
    python3-pip \
    apt clean && \
    apt -y autoremove && \
    rm -rf /var/lib/{apt,dpkg,cache,log} && \
    rm -rf /var/cache/* && \
    rm -rf /var/log/apt/* && \
    rm -rf /tmp/*

# Python Environment Setup
RUN pip3 install torch torchvision torchaudio \
    --extra-index-url https://download.pytorch.org/whl/nightly/cu129 \
    --break-system-packages

RUN git clone \
    --branch ${VERSION} \
    --depth 1 --single-branch \
    https://github.com/comfyanonymous/ComfyUI.git ComfyUI && \
    cd /app/ComfyUI

RUN pip3 install \
    -r /app/ComfyUI/requirements.txt \
    --break-system-packages

EXPOSE 8188
# CMD ["python3", "-u", "/app/ComfyUI/main.py", "--listen", "0.0.0.0", "--port", "8188"]
CMD ["python3", "-u", "/app/ComfyUI/main.py", "--listen", "0.0.0.0", "--front-end-version", "Comfy-Org/ComfyUI_frontend@${VERSION}"]
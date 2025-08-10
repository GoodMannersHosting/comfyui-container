ARG VERSION
ARG BASE_TAG="12.8.1"
ARG CUDA_VERSION="128"
ARG CUDA_NIGHTLY="false"
FROM harbor.cloud.danmanners.com/library/nvidia/cuda:${BASE_TAG}-cudnn-runtime-ubuntu24.04 AS build
LABEL maintainer="daniel.a.manners@gmail.com"
LABEL build_date="2025-07-20"
ARG VERSION
ARG CUDA_VERSION
ARG CUDA_NIGHTLY

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    python3.12 \
    python3-pip \
    wget \
    curl \
    htop

# Python Environment Setup
RUN if [ "${CUDA_NIGHTLY}" = "true" ]; then \
    pip3 install torch torchvision torchaudio \
    --extra-index-url https://download.pytorch.org/whl/nightly/cu${CUDA_VERSION} \
    --break-system-packages; \
    else \
    pip3 install torch torchvision torchaudio \
    --extra-index-url https://download.pytorch.org/whl/cu${CUDA_VERSION} \
    --break-system-packages; \
    fi

RUN git clone \
    --branch ${VERSION} \
    --depth 1 --single-branch \
    https://github.com/comfyanonymous/ComfyUI.git ComfyUI

RUN mkdir -p /app/ComfyUI/scripts

COPY scripts/* /app/ComfyUI/scripts/

RUN pip3 install \
    -r requirements.txt \
    --break-system-packages

RUN git clone https://github.com/ltdrdata/ComfyUI-Manager \
    /app/comfyui-manager && \
    pip3 install -r /app/comfyui-manager/requirements.txt \
    --break-system-packages

EXPOSE 8188
WORKDIR /app/ComfyUI
CMD ["scripts/entrypoint.sh"]
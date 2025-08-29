# Load versions from versions file
ARG VERSION
ARG BASE_TAG
ARG CUDA_VERSION
ARG CUDA_NIGHTLY="false"

# Set default values from versions file if not provided
ARG UV_VERSION="0.8.14"
ARG CUDA_BASE_TAG="12.8.1"
ARG CUDA_VERSION_DEFAULT="128"

# Use provided args or defaults
ARG FINAL_BASE_TAG=${BASE_TAG:-${CUDA_BASE_TAG}}
ARG FINAL_CUDA_VERSION=${CUDA_VERSION:-${CUDA_VERSION_DEFAULT}}

FROM harbor.cloud.danmanners.com/library/nvidia/cuda:${FINAL_BASE_TAG}-cudnn-runtime-ubuntu24.04 AS build
LABEL maintainer="daniel.a.manners@gmail.com"
LABEL build_date="2025-07-20"
ARG VERSION
ARG FINAL_CUDA_VERSION
ARG CUDA_NIGHTLY

WORKDIR /app

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
    python3.12 python3-pip \
    wget curl htop git

# Install uv package manager directly to /usr/local/bin
RUN curl -LsSf https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C /tmp && \
    mv /tmp/uv-x86_64-unknown-linux-gnu/uv /usr/local/bin/uv && \
    rm -rf /tmp/uv-x86_64-unknown-linux-gnu

# Python Environment Setup with uv
RUN if [ "${CUDA_NIGHTLY}" = "true" ]; then \
    uv pip install torch torchvision torchaudio \
    --extra-index-url https://download.pytorch.org/whl/nightly/cu${FINAL_CUDA_VERSION}; \
    else \
    uv pip install torch torchvision torchaudio \
    --extra-index-url https://download.pytorch.org/whl/cu${FINAL_CUDA_VERSION}; \
    fi

RUN git clone \
    --branch ${VERSION} \
    --depth 1 --single-branch \
    https://github.com/comfyanonymous/ComfyUI.git ComfyUI

RUN mkdir -p /app/ComfyUI/scripts

COPY scripts/* /app/ComfyUI/scripts/

# Create virtual environment and install ComfyUI requirements
RUN uv venv /app/venv
ENV PATH="/app/venv/bin:$PATH"
ENV VIRTUAL_ENV="/app/venv"
ENV UV_PROJECT_ENVIRONMENT="/app/venv"

# Install initial requirements
RUN uv pip install -r /app/ComfyUI/requirements.txt

RUN git clone https://github.com/ltdrdata/ComfyUI-Manager \
    /app/comfyui-manager && \
    uv pip install -r /app/comfyui-manager/requirements.txt

# Create a backup of the initial virtual environment for restoration
RUN cp -r /app/venv /app/venv-backup

# Copy pyproject.toml to the backup for version comparison
RUN cp /app/ComfyUI/pyproject.toml /app/venv-backup/pyproject.toml

# Create a persistent directory for user-installed packages
RUN mkdir -p /app/user-packages
ENV UV_CACHE_DIR="/app/user-packages"

# Ensure uv can write to the virtual environment
RUN chmod -R 755 /app/venv

# Create a non-root user for better security
RUN useradd -m -u 1000 -s /bin/bash comfyuser && \
    chown -R comfyuser:comfyuser /app

# Ensure virtual environment is in PATH
ENV PATH="/app/venv/bin:$PATH"

EXPOSE 8188
WORKDIR /app/ComfyUI
USER comfyuser
CMD ["scripts/entrypoint.sh"]
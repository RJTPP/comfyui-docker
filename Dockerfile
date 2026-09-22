FROM nvidia/cuda:13.0.3-cudnn-runtime-ubuntu24.04

ARG COMFYUI_REF=v0.37.0
ARG APP_UID=1000
ARG APP_GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    PATH=/opt/venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    HOME=/opt/comfyui/user

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates git python3 python3-venv libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
       torch==2.11.0 torchvision==0.26.0 torchaudio==2.11.0 \
       --index-url https://download.pytorch.org/whl/cu130

RUN git clone --depth 1 --branch "$COMFYUI_REF" \
       https://github.com/Comfy-Org/ComfyUI.git /opt/comfyui \
    && pip install --no-cache-dir -r /opt/comfyui/requirements.txt \
    && chown -R "$APP_UID:$APP_GID" /opt/comfyui

USER ${APP_UID}:${APP_GID}
WORKDIR /opt/comfyui
EXPOSE 8188

CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--disable-api-nodes"]

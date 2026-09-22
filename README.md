# ComfyUI for Docker

A minimal NVIDIA/CUDA image for running ComfyUI with Docker. It includes
ComfyUI and its Python dependencies, but no models, workflows, secrets, or
third-party custom nodes.

## Versions

- CUDA 13.0.3 runtime on Ubuntu 24.04
- PyTorch 2.11.0, torchvision 0.26.0, torchaudio 2.11.0
- ComfyUI v0.37.0 by default

## Requirements

- Linux with Docker
- NVIDIA GPU and NVIDIA Container Toolkit
- Host directories for models and persistent data

The image runs as numeric UID/GID `1000:1000` by default. Writable directories
must have matching ownership, and models must be readable by that user. Change
`COMFYUI_UID` and `COMFYUI_GID` before building if needed.

## Docker Compose

Copy the example environment file and set both host paths:

```bash
cp .env.example .env
```

```env
COMFYUI_MODELS_DIR=/srv/comfyui/models
COMFYUI_DATA_DIR=/srv/comfyui/data
```

Create these subdirectories under `COMFYUI_DATA_DIR`: `input`, `output`,
`user`, and `custom_nodes`. Then start ComfyUI:

```bash
docker compose up -d
```

Open <http://127.0.0.1:8188>. The port is bound to localhost and the container
has no built-in authentication.

```bash
docker compose stop
```

## Docker

The same image can be built and run without Compose:

```bash
docker build -t comfyui-local:0.1.0 .
docker run -d --name comfyui --gpus 1 \
  -p 127.0.0.1:8188:8188 \
  --mount type=bind,src=/srv/comfyui/models,dst=/opt/comfyui/models,readonly \
  --mount type=bind,src=/srv/comfyui/data/input,dst=/opt/comfyui/input \
  --mount type=bind,src=/srv/comfyui/data/output,dst=/opt/comfyui/output \
  --mount type=bind,src=/srv/comfyui/data/user,dst=/opt/comfyui/user \
  --mount type=bind,src=/srv/comfyui/data/custom_nodes,dst=/opt/comfyui/custom_nodes \
  comfyui-local:0.1.0
```

All source directories must exist before using `docker run --mount`.

## Dokploy

Create a Docker Compose service from this repository and set the environment
variables from `.env.example`. Remove the localhost `ports` entry from the
Compose configuration if you do not want a host port.

In **Domains**, route service `comfyui` to container port `8188`. Check
**Preview Compose** to verify the labels and network Dokploy adds. An explicit
`dokploy-network` entry is unnecessary for this single service when a domain is
configured. See [Dokploy's Compose domains documentation](https://docs.dokploy.com/docs/core/docker-compose/domains).

## Notes

- Models are mounted read-only; input, output, user data, and custom nodes persist
  on the host.
- Custom-node dependencies are not installed automatically. ComfyUI Manager is
  not included.
- Change `COMFYUI_REF` to build another ComfyUI version.
- Rebuilds are not byte-for-byte reproducible because the base image and all
  transitive Python packages are not pinned by digest or hash.
- Validate GPU detection, directory permissions, persistence, and a
  representative workflow on the target host.

Check the Compose configuration without building or starting it:

```bash
docker compose --env-file .env.example config
```

This repository does not run automated image-build or GPU integration tests.

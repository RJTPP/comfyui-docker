# ComfyUI for Docker

A minimal NVIDIA/CUDA ComfyUI image. Models, workflows, user data, and
third-party custom nodes are supplied at runtime, not included in the image.

## Versions

- CUDA 13.0.3 runtime on Ubuntu 24.04
- PyTorch 2.11.0, torchvision 0.26.0, torchaudio 2.11.0
- ComfyUI v0.37.0 by default

## Requirements

- Linux with Docker; Docker Compose for the Compose examples
- NVIDIA GPU and NVIDIA Container Toolkit
- Host directories for models and persistent data

The image runs as numeric UID/GID `1000:1000`. Writable data must be owned by
that user, and models must be readable by it. To use another UID/GID, build
from source with `COMFYUI_UID` and `COMFYUI_GID`.

## Prepare host directories

For a new installation using the example paths:

```bash
sudo mkdir -p /srv/comfyui/models /srv/comfyui/data/{input,output,user,custom_nodes}
sudo chown 1000:1000 /srv/comfyui/data/{input,output,user,custom_nodes}
```

Adjust the paths for your host. Existing files in the data directories must
also be writable by UID/GID `1000:1000`. Models are mounted read-only.

## Use the prebuilt image

The prebuilt image supports `linux/amd64`. `latest` is a moving tag;
use a version tag to pin a release.

### Docker

```bash
docker pull ghcr.io/rjtpp/comfyui-docker:latest
docker run -d --name comfyui --gpus 1 \
  -p 127.0.0.1:8188:8188 \
  --mount type=bind,src=/srv/comfyui/models,dst=/opt/comfyui/models,readonly \
  --mount type=bind,src=/srv/comfyui/data/input,dst=/opt/comfyui/input \
  --mount type=bind,src=/srv/comfyui/data/output,dst=/opt/comfyui/output \
  --mount type=bind,src=/srv/comfyui/data/user,dst=/opt/comfyui/user \
  --mount type=bind,src=/srv/comfyui/data/custom_nodes,dst=/opt/comfyui/custom_nodes \
  ghcr.io/rjtpp/comfyui-docker:latest
```

### Docker Compose

Copy the prebuilt example, edit the host paths and optional `COMFYUI_TAG`,
then start the service:

```bash
cp .env.image.example .env
docker compose -f compose.image.yaml up -d
```

Open <http://127.0.0.1:8188>. The port is bound to localhost; ComfyUI has no
built-in authentication. Stop with `docker stop comfyui` or
`docker compose -f compose.image.yaml stop`, depending on how you started it.

## Build from source

### Docker Compose

Copy the source-build example, edit the host paths or build arguments, and
start the service:

```bash
cp .env.example .env
docker compose up -d
```

Stop with `docker compose stop`.

### Docker

```bash
docker build -t comfyui-local:dev .
```

Run it with the Docker command above, replacing the final image reference
with `comfyui-local:dev`.

## Dokploy

Create a Docker Compose service from this repository. Set **Compose Path** to
`./compose.image.yaml` to pull the prebuilt image or `./compose.yaml` to build
from source. Set the host paths from the matching example environment file.

For a domain-only deployment, remove the localhost `ports` entry in a
deployment-specific Compose copy. In **Domains**, route service `comfyui` to
container port `8188`, then inspect **Preview Compose** for the generated
labels and network. See [Dokploy's domain documentation](https://docs.dokploy.com/docs/core/docker-compose/domains).

## Notes

- Custom-node dependencies and ComfyUI Manager are not installed automatically.
- Source rebuilds are not byte-for-byte reproducible: the base image and all
  transitive Python packages are not pinned by digest or hash.
- Validate GPU detection, directory permissions, persistence, and a
  representative workflow on the target host.

Check either Compose file without starting a container:

```bash
docker compose --env-file .env.image.example -f compose.image.yaml config
docker compose --env-file .env.example -f compose.yaml config
```

This repository does not run automated image-build or GPU integration tests.

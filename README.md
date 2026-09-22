# Minimal ComfyUI for Dokploy

A small, pinned NVIDIA/CUDA ComfyUI image deployed as a **Dokploy Docker
Compose** service. It includes ComfyUI and its Python dependencies, but no
model weights, workflows, secrets, or third-party custom nodes. The default
configuration is for an on-demand GPU workload rather than an always-on UI.

## What's pinned

- NVIDIA CUDA 13.0.3 runtime on Ubuntu 24.04
- PyTorch 2.11.0, torchvision 0.26.0, torchaudio 2.11.0 (CUDA 13.0 wheels)
- ComfyUI v0.37.0 by default, overridable through the `COMFYUI_REF` build arg

Update these versions deliberately and test the resulting image before
deployment. The image has not yet been built or GPU-tested by this repository.

## Prepare the target server

The server selected in Dokploy needs Docker, the NVIDIA Container Toolkit, a
working GPU allocation, and enough free disk space to build the image. Verify
GPU access on that server before deploying.

Create two persistent directories on the **target server**, outside Dokploy's
cloned repository:

```text
/srv/comfyui/models/      # model files, mounted read-only
/srv/comfyui/data/
├── input/
├── output/
├── user/
└── custom_nodes/
```

The paths above are examples; choose paths suitable for your server. Model
subdirectories such as `diffusion_models/`, `text_encoders/`, and `vae/` go
inside the models directory according to the workflow you use. This repository
does not download or synchronize model files.

The image defaults to UID/GID 1000. Set `COMFYUI_UID` and `COMFYUI_GID` to the
owner of the writable data directories if different, and make sure the model
files are readable by that user. Dokploy passes these values as build
arguments; changing them requires an image rebuild.

## Deploy in Dokploy

1. Create a **Compose** service, select **Docker Compose** (not Docker Stack),
   and select the server with the GPU.
2. Connect this Git repository as the source and set the Compose path to
   `./compose.yaml`. The `build: .` context is the cloned repository and is
   supported by Dokploy's Docker Compose mode; Docker Stack does not support
   `build`.
3. In Dokploy's **Environment** tab, set `COMFYUI_MODELS_DIR` and
   `COMFYUI_DATA_DIR` to absolute paths on the target server. Optionally set
   `COMFYUI_REF`, `COMFYUI_IMAGE`, `COMFYUI_UID`, and `COMFYUI_GID`. See
   `.env.example` for example values. Never commit a populated `.env` file.
4. Deploy. In Dokploy's **Domains** tab, add a hostname for service `comfyui`
   at container port `8188`. The service joins `dokploy-network` for this.
   The Compose file does not publish a raw host port.

Keep access to the UI limited to a trusted network or add an authentication
layer. The Compose file itself does not provide authentication. Do not assume
that a Dokploy domain is private merely because no host port is published.

`restart: "no"` keeps this occasional workload from automatically returning
after Docker restarts. A Dokploy deployment can still start it; stop it in
Dokploy when it is not needed. If you prefer an always-on service, change this
policy intentionally after considering GPU capacity.

## Shared-GPU use

If another model server uses the same GPU, stop that workload and confirm its
memory has been released with `nvidia-smi` before starting ComfyUI. When done,
stop ComfyUI and verify the GPU is free before restarting the other service.
This handoff is manual; this repository does not stop or restart other services.

## Updates and rollback

To try a new stable ComfyUI release, change `COMFYUI_REF` in Dokploy and
redeploy with a rebuild. Record the deployed version in Git too, for example
by updating the default in the Dockerfile and Compose file after validation;
otherwise the Dokploy environment is the only record of that change. Test a
representative workflow before keeping the new image.

For a dependable rollback, retain a known-good built image tag or digest.
Setting `COMFYUI_REF` back and rebuilding may resolve different upstream
packages or a changed base image, so it does not necessarily recreate the
previous image byte-for-byte.

## First-deployment checks

- The image builds and the container starts on the selected Dokploy server.
- Container logs show PyTorch detecting the intended NVIDIA GPU.
- Model files are visible inside `/opt/comfyui/models` and cannot be modified
  from the container.
- Input, output, and user data persist under `COMFYUI_DATA_DIR` after a
  container recreation.
- The UI works through the intended Dokploy hostname without publishing port
  8188 on the host.
- A small workflow completes, then stopping ComfyUI releases its GPU memory.

Custom node source can live in the persistent `custom_nodes` directory, but
its Python or system dependencies are **not** installed automatically. Add
only the nodes you need and pin their dependencies in a deliberate image
revision. Avoid in-place package updates that cannot be reproduced by a build.
The bind mount hides any custom nodes baked into that image directory; remove
the mount if you later switch to fully image-managed nodes. ComfyUI Manager is
not installed or enabled in this minimal image.

For local Compose syntax checks, run:

```bash
docker compose --env-file .env.example -f compose.yaml config
```

This does not build the image or prove GPU compatibility.

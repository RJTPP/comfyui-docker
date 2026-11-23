# Build and publish a versioned image manually

Choose an [upstream ComfyUI release](https://github.com/Comfy-Org/ComfyUI/releases).
The image tag combines the upstream version and a packaging revision. For
example, `0.46.0-r1` contains ComfyUI `v0.46.0`. Use `0.46.0-r2` for a new
image with the same ComfyUI version and start at `r1` for each new upstream
version.

From the repository root, set the upstream version and image revision, then
build the image locally.

```bash
comfyui_ref=v0.46.0
image_revision=1
image="ghcr.io/rjtpp/comfyui-docker:${comfyui_ref#v}-r${image_revision}"
# Replace ghcr.io/rjtpp/comfyui-docker with your own registry and image name.

docker buildx build --platform linux/amd64 --load \
  --build-arg "COMFYUI_REF=$comfyui_ref" \
  --tag "$image" .
```

On your NVIDIA host, test a workflow with the new image reference. Use the
[Docker run example in the README](README.md#docker) to start the container.

For a deployment that pulls from GHCR, sign in with an account that can
publish to the package. Then run `docker push "$image"` from the same shell on
the build machine. [GHCR sign-in instructions](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry)

After publishing, set `COMFYUI_TAG=0.46.0-r1` in your prebuilt Compose `.env`
or Dokploy environment and redeploy. To roll back, select the previous image
tag and redeploy again. Update `latest` separately when you want installs
that follow that tag to pick up the release.

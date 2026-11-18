> Historical procedure. Local development now runs on the host with mise and Podman Compose. See the
> [repository setup](../../README.md).

# Development Container Targets

The repository uses one multi-stage `Containerfile` with three outcome images:

- `production` is the deployable runtime image.

The final Containerfile stage aliases `production`, so omitting `--target` does not accidentally
produce a development image.

## Build an image directly

```sh
podman build --target production \
  --tag umaxica-core:production .
```

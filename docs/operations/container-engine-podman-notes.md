# Container Engine Notes (Podman / Docker)

This is a security requirement. Do not bind host credential files into the containers. The internal
PostgreSQL passwords are fixed development-only literals declared inline in `compose.yaml`, so no
credential is bound in from the host. Global and Edge intentionally do not share a host Podman
network; Edge reaches the Rails origin through Cloudflare Workers VPC.

The compose stack at `compose.yaml` is exercised with rootless Podman. Some Compose-compatible
tooling remains useful for static validation, but it is not the supported runtime provider. This
document records the rootless Podman requirements that are easy to miss.

## Restart policies

No service uses `restart: always` or `restart: unless-stopped`. Podman applies no backoff to a
restart policy, so a container that exits immediately on a bad configuration is recreated several
times a second until netns, veth, conmon, and journald churn saturates a CPU — the failure mode
recorded in `research/implementation/2026-08-23-cloudflare-tunnel-restart-storm.md`. The attempt
count is the only bound Compose can express, so every long-running service declares `on-failure:N`:

| Service                                                      | Policy         |
| ------------------------------------------------------------ | -------------- |
| `primary`, `replica`, `valkey`, `valkey-cache`, `valkey-kvs` | `on-failure:5` |
| `fakecloud`                                                  | `on-failure:3` |

A failing _healthcheck_ does not trigger a restart. Podman's `--health-on-failure` has no
Compose-file equivalent, so a container that is alive but unhealthy — a replica that has stopped
streaming, for instance — is reported by `podman ps` and repaired by hand.

`core`, `primary`, `replica`, `valkey`, `valkey-cache`, `valkey-kvs` log through a size-capped
`json-file` driver (`max-size: 10m`, `max-file: 3`) because journald enforces no per-container cap.
Their output does not reach `journalctl`; use `podman logs`, which serves either driver.

No test holds these as assertions any longer: `test/tooling/compose_restart_policy_test.rb` was
removed, and Compose configuration is verified by running it
(`adr/no-test-suite-for-environment-construction.md`).

## PostgreSQL storage

Primary and replica data use named volumes. The no-tmpfs baseline is intentional: explicit tmpfs and
`shm_size` settings are not part of the current stack. Reintroducing either requires workload and
memory-pressure measurements.

## SELinux

On Fedora, RHEL, and other SELinux-enforcing hosts, bind-mounted host paths must be labeled before
the container can read them. The compose file marks read-only config bind mounts with `:z` (shared
label). The workspace bind is labeled `Z` (private) rather than shared, so SELinux does not relabel
the host source tree for other containers.

If a service fails to read a mounted file with "permission denied" on an SELinux host even though
POSIX permissions look correct, relabel manually:

```bash
chcon -Rt container_file_t podman/<service>/
```

## Podman-specific compose settings

`compose.yaml` makes the stack Podman-friendly:

- `userns_mode: keep-id` for UID mapping.
- no `user:` key on `core`, so the in-image UID wins instead of double-mapping.
- no tmpfs mount for the workspace `tmp/` and `log/` paths, because rootless Podman has historically
  been unreliable with them on tmpfs.

Run the stack with the developer overlay layered on the base compose file:

```bash
podman compose -f compose.yaml up
```

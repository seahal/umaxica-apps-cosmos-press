# Development Host Port Exposure

Run Rails and Vite on the host. Podman Compose supplies PostgreSQL, Valkey, and FakeCloud. Each
checkout has its own Compose project, named volumes, and loopback ports.

| Checkout   | Rails |  Vite |   PostgreSQL |      Valkey | FakeCloud |
| ---------- | ----: | ----: | -----------: | ----------: | --------: |
| access     |  3001 |  3046 |   5432, 5433 |   6379–6381 |      4566 |
| governance | 13001 | 13036 | 15432, 15433 | 16379–16381 |     14566 |
| press      | 23001 | 23036 | 25432, 25433 | 26379–26381 |     24566 |
| sphere     | 33001 | 33036 | 35432, 35433 | 36379–36381 |     34566 |

Publish infrastructure ports explicitly on `127.0.0.1`. Services within Compose use their service
names and container ports.

Rails tests use the checkout-specific socket in `tmp/sock/pg`. The host port configuration is only
for development processes and host tools. See [setup](../../README.md) for commands.

Use `podman compose config` to check the configured bindings and `podman compose ps` to verify the
running stack. See `test/tooling/compose_host_port_exposure_test.rb` for the port contract.

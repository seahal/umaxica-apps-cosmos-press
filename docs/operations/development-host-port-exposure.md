# Development Host Port Exposure

Rails and Vite run on the host. Podman Compose runs PostgreSQL, Valkey and FakeCloud. All published
ports are on IPv4 loopback.

| Service                       | Host ports          |
| ----------------------------- | ------------------- |
| Rails                         | 3030                |
| Vite                          | 3036                |
| PostgreSQL writer and replica | 25432, 25433        |
| Valkey                        | 26379, 26380, 26381 |
| FakeCloud                     | 24566               |

Rails tests use the primary socket in `tmp/pg`. Within Compose, services use DNS names and container
ports. Host port publications must explicitly bind to loopback, as checked by
`test/tooling/compose_host_port_exposure_test.rb`.

The optional `tunnel` and `workers-vpc` profiles reach Rails through pasta's mapped host loopback
and publish no host ports. Their tokens come from local settings.

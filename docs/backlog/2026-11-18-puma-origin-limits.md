# Puma connection handling and origin body limits

**Decision pending.** The Ruby audit flagged seven upstream advisories against Puma 8.0.2. The
configured server handles HTTP before controller authentication. Upstream lists 8.0.3 as the fixed
8.x release for all seven. The review identified the following prerequisites at the origin.
[Locked version](../../Gemfile.lock#L767) · [Listener and workers](../../config/puma.rb#L34) ·
[Container command](../../Containerfile#L223)

| Upstream advisory                                                                                   | Relevance to Press                                                                                                                                         |
| --------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Reactor timeout ordering](https://github.com/puma/puma/security/advisories/GHSA-m5xw-3hrw-qcmf)    | Ordinary HTTP connection processing uses the reactor. Request buffering at the proxy affects exposure to slow clients.                                     |
| [Graceful shutdown](https://github.com/puma/puma/security/advisories/GHSA-jm4r-w4xx-qxw7)           | Exposure depends on shutdown mode and upstream buffering. Development declares two workers. Single-mode behavior cannot be assumed for that configuration. |
| [File descriptor exhaustion](https://github.com/puma/puma/security/advisories/GHSA-rf6g-xhmp-gm7v)  | The HTTP accept loop runs before Rails. Effective connection limits at the proxy and process were unverified.                                              |
| [Reactor interim responses](https://github.com/puma/puma/security/advisories/GHSA-xw3h-pgr9-3vg7)   | Applies to queued HTTP request handling when client behavior can reach the origin. Forwarding behavior is deployment-specific.                             |
| [TLS or file responses](https://github.com/puma/puma/security/advisories/GHSA-x646-wp7c-h9mg)       | The configured bind uses plain TCP. File responses can still be relevant when Puma serves files. Proxy response buffering changes the impact.              |
| [TLS control server identity](https://github.com/puma/puma/security/advisories/GHSA-86xc-wrr9-xmmq) | No TLS control server or matching management-client configuration was identified in this repository.                                                       |
| [TLS cipher filter parsing](https://github.com/puma/puma/security/advisories/GHSA-r885-m39c-939g)   | No matching Puma TLS cipher filter was identified. The deployment configuration assumes TLS terminates upstream.                                           |

**Independent body-size issue.** Puma 8.0.2 defaults `http_content_length_limit` to `nil` and can
buffer bodies to temporary files before calling Rack. Press does not set this Puma option. Rails
enforces 1 MiB for JSON and rejects unsupported JSON content encodings. Its middleware does not
cover all content types or bound pre-Rack disk consumption. The Shrine 10 MiB rule runs later still.
No saturation or outage was measured.
[Puma default](https://github.com/puma/puma/blob/v8.0.2/lib/puma/configuration.rb#L146) ·
[Puma buffering](https://github.com/puma/puma/blob/v8.0.2/lib/puma/client.rb#L507) ·
[JSON boundary](../../lib/request_body_size_limit.rb#L13) ·
[Attachment boundary](../../app/uploaders/publishing_media_uploader.rb#L4)

**Decision for runtime and ingress owners.** Consider the Puma update separately from an origin body
budget. Record how each enabled ingress buffers requests and responses, which limits apply to all
body types, and which entry points can reach Puma directly. A package update addresses the listed
version findings. Independent evidence is needed for body, disk and connection budgets.

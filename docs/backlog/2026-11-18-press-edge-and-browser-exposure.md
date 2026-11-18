# Press monitoring paths, origin exposure and browser transport

**Decision pending.** The monitoring contract calls both machine JSON endpoints internal. Its
documented Cloudflare block covers `/health` and `/health/*`. Neither `/api/v0/health.json` nor
`/api/v0/revision.json` matches those paths. The application accepts anonymous requests to both on
the corresponding hosts. Health checks exercise database writers and readers. Revision returns the
deployment identifier when set, plus a timestamp. The text `/revision` route also answers
anonymously. No deployed edge rule was inspected.
[Monitoring contract](../operations/health-check.md#L13) ·
[Edge rule](../operations/health-check.md#L32) · [Routes](../../config/routes/info.rb#L10) ·
[Dependency checks](../../app/services/health.rb#L185) ·
[Revision responses](../../app/controllers/concerns/application_revision_rendering.rb#L24)

## Listener and storage inventory

| Component                      | Repository observation                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Development Compose host ports | FakeCloud 24566, PostgreSQL primary/replica 25432/25433 and Valkey stores 26379–26381 bind to IPv4 loopback by default. Compose declares no SSH host publication. [Ports](../../compose.yaml#L49)                                                                                                                                                                                                                                                                            |
| Rails and tunnels              | The standard development Procfile requests `127.0.0.1`. Puma's own configuration specifies a wildcard TCP bind, and the production image declares 8080. The working-tree Compose starts two connectors and binds their metrics to container loopback. Actual hostnames, Access coverage and host firewalls were unverified. [Procfile](../../Procfile.dev#L1) · [Puma](../../config/puma.rb#L38) · [Image](../../Containerfile#L218) · [Connectors](../../compose.yaml#L286) |
| Staging and object storage     | The repository's staging-development provider targets FakeCloud. The shared bucket module sets all four S3 public-access blocks. Applied bucket policies, VM ingress and cloud state were outside the review. [Staging provider](../../terraform/environments/staging-development/providers.tf) · [Bucket module](../../terraform/modules/object_storage/main.tf#L25)                                                                                                        |
| Production                     | The production boot guard stops this revision before requests are served. The runbook assigns general HTTP abuse controls to CloudFront/AWS WAF and the ALB, and describes Cloudflare for the development tunnel. Neither service's effective rules were verified. [Boot guard](../../config/application.rb#L93) · [Edge responsibilities](../operations/health-check.md#L86)                                                                                                |

## Browser settings to preserve or reassess

- Production configuration assumes an SSL-terminating proxy, forces SSL, and configures one year of
  HSTS with subdomains. Preload is off. The host allowlist and trusted-proxy handler constrain which
  headers the app accepts. Whether plaintext can reach a deployed origin is an infrastructure
  question. [TLS](../../config/environments/production.rb#L40) ·
  [Hosts](../../config/environments/production.rb#L157) ·
  [Forwarded headers](../../lib/trusted_forwarded_headers.rb#L20)
- The Rails session and RP credential cookies are host-only, HttpOnly and SameSite=Lax. Production
  sets Secure and uses the host prefix. Development leaves Secure off unless
  `FORCE_SECURE_COOKIES=1`. Effective settings on remote development hostnames were unverified.
  [Session options](../../lib/jit_session_cookie_config.rb#L9) ·
  [RP cookies](../../app/services/oidc_rp_browser_credential_contract.rb#L109)
- CSP is enforced with script nonces and `strict-dynamic`. Connections default to self, objects are
  disabled, and development adds Vite WebSocket origins. Image, font and style directives permit
  broader HTTPS sources. The CORS initializer enables no broad cross-origin grant. Edge overrides
  and emitted headers were unverified.
  [CSP](../../config/initializers/content_security_policy.rb#L44) ·
  [CORS initializer](../../config/initializers/cors.rb)

**Decision for monitoring and edge owners.** Specify the intended public status of each text and
JSON path, then compare it with the effective rules for each exposed hostname. The useful evidence
would distinguish a public request denied at the edge from an internal probe that still works. For
remote development, record which host terminates TLS and the cookie attributes delivered there.

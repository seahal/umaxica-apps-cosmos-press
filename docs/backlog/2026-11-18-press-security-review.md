# Press security review, 2026-11-18

**Decision status** — Deferred for owner review. Each row can be considered independently.

The review covered the Press repository at `57c72d323dd157fcacd7aef2e145d9bf0d8132e6`. The working
tree also contained an existing change to `compose.yaml` that removed profile gates from two
development tunnel connectors. That change affects the development exposure assessment. Press owns
Edit, twelve public content cells and operator tools. Access owns the identity provider. At this
revision Rails stops unconditionally on production boot. Production configuration expresses intent,
while actual deployment and edge policy require separate evidence.
[Surface ownership](../../README.md#routing) ·
[Production boot guard](../../config/application.rb#L93)

## Decision index

| Topic                                                                                      | What prompted the entry                                                                                                          |
| ------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| [Development dashboard credentials](2026-11-18-development-dashboard-credentials.md)       | Tracked defaults are effective credentials for Flipper when no override is present. Reachability determines impact.              |
| [Edit session revocation](2026-11-18-edit-session-revocation.md)                           | An expired access JWT can leave a renewable session after a refused sign-out. Upstream revocation also has a delivery window.    |
| [Puma connections and request bodies](2026-11-18-puma-origin-limits.md)                    | Seven dependency alerts with different prerequisites, plus buffering before Rails checks the body.                               |
| [Health, edge and browser exposure](2026-11-18-press-edge-and-browser-exposure.md)         | The documented public block omits internal JSON probes. Listener exposure and browser protections depend on the entry point.     |
| [Errors and sensitive logs](2026-11-18-press-errors-and-sensitive-logs.md)                 | Development exception pages and malformed JSON at DEBUG can expose additional data.                                              |
| [Request and logging budgets](2026-11-18-press-request-budgets.md)                         | Edit authenticates before its default throttle. Public content and CSP reports consume work beyond a request count.              |
| [PostgreSQL and JavaScript dependencies](2026-11-18-press-dependency-reachability.md)      | A development database patch and a build-time glob advisory require different reachability decisions.                            |
| [Access identity boundary](2026-11-18-access-identity-boundary.md)                         | Cross-environment isolation, state consumption, account verification and recovery span two repositories.                         |
| [Authorization and route inventory](2026-11-18-press-authorization-and-route-inventory.md) | Public snapshots, unavailable management authority, operator tools and framework routes have different admission rules.          |
| [Input and storage boundaries](2026-11-18-press-input-and-storage-boundaries.md)           | Input-to-sink checks found bounded paths and areas to revisit if new renderers, destinations or upload endpoints are introduced. |
| [Build artifacts, secrets and CI](2026-11-18-press-build-and-ci-exposure.md)               | Current build output, source maps, Git pins and mutable CI action references affect future deployments.                          |

## Candidates retained for future triage

Several signals looked concerning until their callers or deployment conditions were traced. Keep
their prerequisites with the alert when deciding whether to reopen them.

- **A route exists.** The management API stops before the database and the role guard refuses
  several mounted controllers. Reassess when Governance is connected or controller ownership
  changes.
- **A dependency scanner flags a package.** Picomatch receives build configuration in the reviewed
  path. Two Puma advisories require TLS options missing from the repository configuration. Reassess
  when runtime inputs, the server command or the TLS terminator changes.
- **A browser artifact could expose source.** The build supports hidden maps, but the reviewed
  stylesheet-only output contained none. Inspect the published file list when a JS entry is added.
- **An identity operation has no local handler.** Email confirmation, recovery and invitation
  controls need evidence from Access. Their absence in Press establishes ownership scope only.

## Verification at the reviewed revision

| Check                                      | Observed result                                                                                                                                                                                                                                                                                                                                        |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Existing Rails tests in three focused runs | 55 tests / 419 assertions for OIDC, local authentication, publishing policy/query, callback and logout return. 30 / 267 for management, public content, CSP, mounted engines, CSRF and revocation. 46 / 228 for return paths, CSP parsing, outbound HTTP, redaction and attachments. Total 131 tests / 914 assertions, zero failures, errors or skips. |
| Brakeman 8.1.0                             | Zero warnings and zero scan errors.                                                                                                                                                                                                                                                                                                                    |
| Ruby dependency audit                      | Seven Puma alerts. Local advisory data matched upstream HEAD `cad74bbe85c643bb9456450f357d6288c9ded2f8`.                                                                                                                                                                                                                                               |
| Bun dependency audit                       | One High alert for picomatch 4.0.7 in the Vite build dependency tree.                                                                                                                                                                                                                                                                                  |
| Development route enumeration              | 300 entries in the route set. Runtime role inspection distinguished mounted routes from actions a process can serve.                                                                                                                                                                                                                                   |
| Isolated production-mode Vite build        | One stylesheet and two manifests. No JavaScript chunk or source map in that output.                                                                                                                                                                                                                                                                    |

The review included static tracing and focused local tests. There were no live-origin requests,
timing measurements, load tests or checks of the identity provider, deployed CDN/WAF rules, registry
images, prior Git history or stored CI logs. A passing check records what it exercised. The
reference standard was OWASP ASVS 5.0.0, tag `v5.0.0_release`, commit
`5cf9b032440be53ce345ab3c130fda46ba1ce7a2`.
[ASVS release](https://github.com/OWASP/ASVS/releases/tag/v5.0.0_release)

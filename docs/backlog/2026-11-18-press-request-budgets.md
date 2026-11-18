# Press request limits and shared resource consumption

Deferred for owner review.

Review date 2026-11-18. Source revision `57c72d323dd157fcacd7aef2e145d9bf0d8132e6`. The application
declares request counters for Edit browser actions, OIDC closure and CSP intake. They leave gaps
during counter-store connection failures and, on Edit, before some credential work. The review
traced code and inspected configured limits. It did not measure capacity, generate traffic, or
inspect live CDN, provider, database or logging quotas. An existing working-tree change to
`compose.yaml` was present. The current Rails production boot guard prevents this checkout from
establishing deployed behavior. [Boot guard](../../config/application.rb#L93)

## Rate limits and failure behavior

| Caller and operation                                                                         | Enforced budget in source                                                                                                                                      | Work outside that budget                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| -------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Edit browser controllers inheriting the Edit application controller, including sign-in entry | 300 requests/minute per remote IP, shared scope. Excess returns 429 with a 60-second retry interval when the counter works.                                    | The role and FQDN gates run early. Safe-request authentication and unsafe-request admission/refresh run before the controller counter. Depending on the presented credentials, local session checks or a remote refresh attempt can precede it. Unsafe requests check browser provenance and CSRF first. [Order and counter](../../app/controllers/edit/org/application_controller.rb#L30) · [Safe](../../app/controllers/concerns/browser_rp_safe_request_refresh.rb#L11) · [Unsafe](../../app/controllers/concerns/browser_rp_unsafe_request_refresh.rb#L12) |
| OIDC back-channel closure                                                                    | 60 requests/minute per remote IP. The controller callback precedes the action's signed logout-token verification.                                              | A valid event writes a receipt and local revocation state. The limiter does not guarantee a global event or provider quota. [Counter](../../app/controllers/edit/org/oidc/closures_controller.rb#L14) · [Receiver](../../app/controllers/concerns/rp_backchannel_logout_endpoint.rb#L15)                                                                                                                                                                                                                                                                       |
| Anonymous CSP reports                                                                        | 120 requests/minute using the Rails default remote-IP key and controller scope. Each intake is bounded at 64 KiB. A rate-limited report receives 204.          | A single accepted request may generate multiple application log events. The intake has no separate event-count budget. [Counter and read limit](../../app/controllers/concerns/csp_violation_report.rb#L19) · [Size and event fan-out](../../app/services/csp_violation_report_intake.rb#L70)                                                                                                                                                                                                                                                                  |
| Anonymous published article reads                                                            | Twenty entries per list page, a 60-second shared-cache window and validation of the requested page. No origin-side frequency limit was found on these actions. | An origin request can run pagination, publication/taxonomy queries and decryption before ETag validation. [Bare controller](../../app/controllers/info/org/bare_controller.rb#L8) · [Page size and query](../../app/queries/publishing_published_entries_query.rb#L4) · [Rendering](../../app/controllers/concerns/publishing_content_rendering.rb#L65)                                                                                                                                                                                                        |
| Health and revision probes                                                                   | Health responses disable caching. Readiness has a 0.2-second per-database deadline and one-second overall deadline.                                            | Each readiness or aggregate calculation attempts writer and reader queries for the Publishing database. Edit also checks its RP database. Liveness and startup only check local process state. Counter or concurrency guarantees at the monitored origin were not established. [Database check](../../app/services/health.rb#L154) · [Edit profile](../../app/services/health.rb#L248) · [Overall timeout](../../app/services/health.rb#L284)                                                                                                                  |

The environment configures the ordinary controller counters through a Valkey-backed
`RedisCacheStore`. At the locked Rails revision, the cache store's `increment` handles
`RedisClient::ConnectionError` by calling the error handler and returning its configured fallback,
`nil`. The application handler logs the store, operation and error class. Rails rate limiting
rejects only if the count exists and exceeds the limit. Consequently, a request that reaches the
counter during that connection failure continues past it. FQDN availability and authentication can
still independently refuse the request. Other failures, especially loss of the flag store, can close
the service. [Production store configuration](../../config/environments/production.rb#L108) ·
[Error handler](../../lib/umaxica/valkey/store_error_handler.rb#L11) ·
[Pinned framework revision](../../Gemfile.lock#L32) ·
[FQDN gate](../../app/controllers/concerns/fqdn_availability_gate.rb#L65)

JWKS refetch has an independent guard. Unknown signing-key IDs share a per-issuer 30-second window,
with a 10-second lease. A Valkey outage uses a process-local window. Multiple workers may then fetch
independently. Sign-out uses a bare controller and does not inherit the 300/minute Edit browser
limit. Its mutation requires current credentials and can call the provider's revocation endpoint.
[JWKS limiter](../../app/adapters/oidc_jwks_refetch_limiter.rb#L10) ·
[Sign-out admission](../../app/controllers/edit/org/sign/outs_controller.rb#L33) ·
[Remote revocation](../../app/controllers/concerns/oidc_rp_logout_launcher.rb#L173)

## Per-request work and external ownership

- **CSP log volume.** The intake parses an array, sanitizes its members and publishes one event per
  accepted report. The subscriber writes an application log for each event. The byte limit bounds
  input size, while the number of generated records depends on the batch. The review found no
  event-count cap or sampling step on this path. Logging cost and downstream limits depend on
  deployment. [Batch parsing](../../app/services/csp_violation_report_intake.rb#L85) ·
  [Subscription](../../config/initializers/event_subscribers.rb#L6) ·
  [Log write](../../app/subscribers/csp_violation_subscriber.rb#L9)
- **Public database reads.** A full or conditional article list fetch builds the payload before
  evaluating the ETag. Public article fields include the structured body; list length bounds records
  per page, while per-record body size, cache hit ratio and actual query cost determine throughput.
  The sign-in request budget does not extend to these host-local bare controllers.
  [JSON rendering](../../app/controllers/concerns/publishing_content_rendering.rb#L68) ·
  [Encrypted content](../../app/models/concerns/publishing_encrypted_content.rb#L13) ·
  [Representation](../../app/serializers/publishing_entry_serializer.rb#L28)
- **Identity and communications.** An unauthenticated browser can start an OIDC flow after CSRF
  admission. Each POST replaces the browser's pending flow. Access owns the external identity
  provider. Press exposes no local registration, email verification, password reset, invitation
  delivery or OTP/SMS dispatch action. This review found no validated recipient-level rate, spend
  ceiling, resend cooldown, provider contract or account-enumeration behavior. Verify those
  guarantees against Access and the providers serving the deployed client.
  [Sign entry](../../app/controllers/concerns/oidc_rp_sign_entry.rb#L11) ·
  [Pending flow](../../app/controllers/concerns/oidc_sso_initiator.rb#L138) ·
  [External identity ownership](../security/public-entrypoints.md#L22)
- **Other resources.** The routes reviewed did not expose payment, LLM, SMS, media transcoding, GIS,
  arbitrary job submission or direct object-storage uploads to anonymous callers. Mission's queue
  controls have a credential boundary. Publishing management calls carry a client assertion and the
  operator credential, use two-second connect and five-second read timeouts, and currently receive a
  service-unavailable response from the local authority endpoint. The timeouts bound individual
  attempts. The aggregate resource budget remains unverified.
  [Operator and content routes](../../config/routes.rb#L4) ·
  [Storage routes](../../config/application.rb#L104) ·
  [Publishing client](../../app/adapters/publishing_authority_client.rb#L17) ·
  [Authority refusal](../../app/controllers/concerns/publishing_authority_api_endpoint.rb#L23)
- **Distinguishable responses.** An unpublished/archived entry or missing ID produces the public
  not-found response. Matching published entries intentionally return the publication. Management
  calls stop with 503 before object lookup. The review did not establish a bulk account, invite,
  API-key or payment enumeration path, or measure response-size and latency differences.
  [Public detail](../../app/controllers/concerns/publishing_content_rendering.rb#L88) ·
  [Selection](../../app/queries/publishing_published_entries_query.rb#L36) ·
  [Management refusal](../../app/controllers/concerns/publishing_authority_api_endpoint.rb#L23)

## Decisions and evidence needed

1. Decide how sign, closure and telemetry routes should behave when their shared counter is
   unavailable. Verify failure behavior and the earliest costly credential work separately. Existing
   authentication and CSRF ordering constrains any change to the counter location.
2. Establish an acceptable number of CSP events per request and per interval, plus the owner of the
   downstream log budget. Use representative, disposable intake data to verify a proposed limit
   before changing the telemetry contract.
3. Obtain effective edge rules, origin restrictions and per-route counters for the running
   environment. The health runbook assigns internal path blocking to externally managed Cloudflare
   rules, while the public HTTP abuse design assigns generic traffic limits to CloudFront and AWS
   WAF. Its listed path block omits the machine JSON endpoints. Reconcile the intended perimeter
   with the actual deployment, including the IP forwarded to Rails.
   [Health block](../operations/health-check.md#L38) ·
   [Public abuse ownership](../../adr/dos-and-firewall-controls-at-cdn-aws-edge-not-in-rails.md#L42)

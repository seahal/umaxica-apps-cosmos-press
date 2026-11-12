# Public Entrypoints

Application routes are private by default unless their concrete controller/action declares a public
authentication mode. This inventory is enforced by
test/unit/security/public_entrypoint_inventory_test.rb; update the test and this document together
when adding a public route.

| Category                     | Current entrypoints                                                               | Boundary                                                                                              |
| ---------------------------- | --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `PUBLIC_ROOTS`               | Docs, Help, Info and News roots; Edit root and sign entry                         | Each route stays on its surface host. Content roots are thin public pages.                            |
| `PUBLIC_HEALTH`              | Surface-local health summaries and liveness/readiness/startup probes              | Plain or JSON health responses expose no credentials or topology.                                     |
| `PUBLIC_REVISION`            | Surface-local revision and api/v0/revision.json                                   | Returns only the deployment revision representation.                                                  |
| `PUBLIC_CSP_REPORTS`         | POST csp-violation-report on retained app surfaces                                | Bounded browser telemetry; does not mutate actor or session state.                                    |
| `PUBLIC_CONTENT_READ_APIS`   | GET api/v0/entries and GET api/v0/entries/:public_id on Docs, Help, Info and News | Read-only, host-local publishing content.                                                             |
| `PUBLIC_EDIT_BROWSER_RP`     | Edit GET/POST sign, interruption page, OIDC callback and back-channel closure     | OIDC state, nonce, PKCE, callback binding, client authentication and session checks remain mandatory. |
| `PUBLIC_EDIT_SIGN_OUT`       | Edit sign-out request and completion pages                                        | Public page reachability does not bypass session and logout transaction checks.                       |
| `PUBLIC_EDIT_PUBLISHING_API` | Edit api/v0/publishing/{surface}/{audience}/entries/*                             | Server-to-server authentication and PublishingEntryPolicy authorize each operation.                   |

Mission, Flipper, Blazer, PgHero, Swagger and Coverband are mounted operator tools with their own
host constraints and credential checks. They are not application controller routes in this table.

No local Auth, Base, Core, Palm, Tech, Visa or Warp routes are served. Edit's relying-party flow
delegates authentication to its configured external Auth/Visa provider; public availability of the
provider does not add those surfaces to this Rails application.

Every route not covered above must be private or fail closed. Host constraints, authentication mode,
protocol validation and policy authorization remain separate checks.

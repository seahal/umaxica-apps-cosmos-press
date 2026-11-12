# Press Round 2 Surface Cleanup — Final Zero-Caller Audit

Date: 2026-11-11  
`git rev-parse HEAD`: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`  
Uncommitted changes affected results: **yes**. The worktree was already substantially dirty; the
cumulative diff below does not isolate changes made only for this round. No commit was created. No
model or migration was deleted, and no database was dropped. Test verification used configured test
databases.

## Owned surfaces and final route counts

The owned surface list was rechecked against `README.md`: Docs, News, Help, and Info on APP/COM/ORG
(including `.com`); Edit ORG; Mission, Flipper, Blazer, PgHero, Swagger, and Coverband; and the
unknown-host 404 handler. The four `.com` host blocks remain. Edit's root remains.

| Host-constraint group | Classification                 |                           Routes emitted |
| --------------------- | ------------------------------ | ---------------------------------------: |
| Docs APP / COM / ORG  | OWN                            |                       10 each (30 total) |
| News APP / COM / ORG  | OWN                            |                       10 each (30 total) |
| Help APP / COM / ORG  | OWN                            |                       10 each (30 total) |
| Info APP / COM / ORG  | OWN                            |                       10 each (30 total) |
| Edit ORG              | OWN                            |                                      163 |
| Mission Control Jobs  | OWN operator tool              |         25 (mount plus 24 engine routes) |
| Flipper               | OWN operator tool              |                             1 Rack mount |
| Blazer                | OWN operator tool              |         32 (mount plus 31 engine routes) |
| PgHero                | OWN operator tool              |         26 (mount plus 25 engine routes) |
| Swagger API/UI        | OWN operator tool              | 2 engine mounts; no inner routes emitted |
| Coverband             | OWN operator tool, conditional |              0 emitted in this route run |
| Unknown-host fallback | OWN boundary handler           |                                        1 |
| **Total**             |                                |                                  **370** |

The route command emitted 290 application-table entries and 80 nested Mission/Blazer/PgHero engine
entries. There are no content/page routes on the twelve Docs/News/Help/Info host blocks. Each block
retains six non-API operational routes: revision, health, three health probes, and CSP reporting;
four API routes remain. Tests assert `/` returns 404 for the twelve host forms and that retained
routes still work. The Edit root remains covered.

### Controller namespace inventory

| Current namespace/area                                      | Classification             |      Current files |
| ----------------------------------------------------------- | -------------------------- | -----------------: |
| `docs`                                                      | OWN; APP/COM/ORG           |                 30 |
| `news`                                                      | OWN; APP/COM/ORG           |                 30 |
| `help`                                                      | OWN; APP/COM/ORG           |                 30 |
| `info`                                                      | OWN; APP/COM/ORG           |                 30 |
| `edit/org`                                                  | OWN                        |                 57 |
| `concerns`                                                  | OWN shared controller code |                 67 |
| Root `ApplicationController`, `UnknownHostsController`      | OWN base and host boundary |                  2 |
| Mission Control Jobs, Flipper, Blazer, PgHero, Rswag API/UI | OWN mounted operator tools | Engine controllers |

Foreign/retired controller roots `auth`, `base`, `core`, `palm`, `tech`, `visa`, and `warp` are
absent. The `guid` and `performance` route files are also absent. The current `config/routes/`
contains exactly `docs.rb`, `edit.rb`, `help.rb`, `info.rb`, `news.rb`, and the six operator-tool
route files. There are no current route targets in the removed controller namespaces. Operator tools
retain the route-local development aliases under `*.core.dev.localhost`, as listed in `README.md`.

### Operator-tool host literals retained as instructed

These route constraint lines are unchanged:

- `config/routes/mission.rb:7` — `mission-press.umaxica.dev`
- `config/routes/flipper.rb:6` — `flipper-press.umaxica.dev`
- `config/routes/blazer.rb:6` — `blazer-press.umaxica.dev`
- `config/routes/pghero.rb:6` — `pghero-press.umaxica.dev`
- `config/routes/swagger.rb:6` — `swagger-press.umaxica.dev`
- `config/routes/coverband.rb:9` — `coverband-press.umaxica.dev`

## Cleanup and retained behavior

- Removed the Rails homepage routes from all twelve Docs/News/Help/Info host blocks, plus their
  root-only controllers, views, helpers, locale entries, and tests. The named backlog entry records
  `.com` retention and homepage completion.
- Removed retired route namespaces and foreign controller trees. The retained route set has no Auth,
  Visa, Base, Tech, Core, Warp, Palm, Guid, or Performance host.
- Removed `database_selector`, `database_resolver`, and `database_resolver_context`; no
  selector/resolver references remain under `config/`. The remaining `connected_to(role: :reading)`
  locations are:

  - Runtime: `app/controllers/concerns/preference_transport.rb:93`.
  - Tests: `test/controllers/concerns/authentication/audit_writer_test.rb:198,211,262`;
    `test/models/security_consumed_jti_test.rb:30`;
    `test/services/rp_request_authenticator_test.rb:98`;
    `test/models/flow_expiry_commit_test.rb:37`; `test/operations/rp_refresh_committer_test.rb:172`;
    `test/operations/rp_callback_committer_test.rb:128`;
    `test/operations/rp_cell_session_revoker_test.rb:54`;
    `test/operations/rp_refresh_logout_concurrency_test.rb:169`.

- Removed the remaining Google/Apple sign-in test path and provider-specific test setup. The
  provider registry, local provider sign-in controllers/adapters, and provider-only gems were
  removed in the earlier hard reset. This round also removed the SQL-log test that created
  Google/Apple `ClientExternalIdentity` rows.
- Kept `IdentitySocialCeremonyContract` provider values because model validators use them to
  preserve constraints on retained ceremony records until the separate model cleanup.
  `SignUpArtifactCleanup` still erases pending historical social identities, and
  `SocialAuditDeliveryJob` drains persisted audit rows; neither starts a provider sign-in flow. The
  old Apple-notification-named test file contained credential-inventory and FQDN tests, so it was
  renamed to match its actual coverage. `google-protobuf` remains a transitive dependency; there is
  no direct OmniAuth dependency.
- Removed `SessionLimitGate` and its unused Edit controller include. Removed stale tests that
  exercised retired Base/Core RP clients, local Auth sign-in, or deleted classes. Remaining Edit RP
  OIDC adapter tests use the registered Edit ORG client.
- Removed the unused identity-graph repair chain: `app/operations/identity_graph_provisioner.rb`,
  `app/services/base_selector_bootstrap_authority.rb`, `app/operations/client_persona_creator.rb`,
  `app/services/acme_selector.rb`, and `lib/tasks/identity_graph_repair.rake`; removed its
  concurrency test. Removed three retired Base OP concurrency tests and the local Auth sign-in
  token-uniqueness test. A source search found no remaining references to these removed classes or
  task.
- The final zero-caller audit removed `OrgAdminAuthorityClient`, `VisaSensitiveAdmissionClient`,
  `AuthenticationLogoutAllSessions`, `TotpWindowConsumer`,
  `ProcessorErasureNotificationReceiptConsumer`, `StepUpAuditOutboxWriter`, and the uncalled
  `AgentCreator`, `BureauCreator`, and `EnterpriseCreator`. Their dedicated tests or test cases were
  removed. Current Edit RP logout still uses `AuthenticationLogoutCurrentSession`; the processor
  delivery job verifies and applies receipts; and `StepUpAuditDeliveryJob` remains to process
  persisted audit outbox rows. The model/database inventory below retains every model and migration.
- Updated the step-up audit Mermaid inventory to show retained-row delivery only: the producer has
  no remaining production caller, while the scheduled job remains for persisted audit rows. Removed
  a no-op Apple credential revocation call from historical sign-up cleanup and removed the obsolete
  `/social/google` test comment.
- Removed `docs/shared/design/social_login.md`, an unimplemented Google/Apple provider-login plan
  with no callers. Updated the current session-reset policy to remove its retired social-auth state
  and callback references, the authentication-assurance document and deprecated phase-1 spec to
  label their former social requirements historical, and the Valkey runbook to describe only the
  retained Jump RT JWKS cache. The Auth ceremony document and August authentication-boundary audit
  remain explicitly historical records.
- Removed `docs/test-migration/any_instance_stub_removal_plan.md`; its target list and examples
  described retired controller/test trees, and no current document linked to it.
- Restored `test/fixtures/operator_tokens.yml` and `test/fixtures/operator_device_sessions.yml`:
  current Edit RP browser authentication and its model tests still use these records.
- Updated the public-ID invariant to scope its per-model test requirement to the retained
  `PublishingRecord` and `RpEditOrgRecord` models. The removed foreign model tests remain deferred
  with their models, as required; the guard no longer demands an owned-surface test for them.
- Kept `SignOutNoticeStore`. Edit's OIDC RP logout launcher reads it, and the shared sign-out
  concern issues and consumes it (`app/controllers/concerns/oidc_rp_logout_launcher.rb`,
  `app/controllers/concerns/sign_out_notice.rb`).
- No `.env*` values were read, printed, or changed in this round. The earlier hard reset removed
  these retired URL variable names from `.env.container.devcontainer` and the corresponding readers:
  `PRIVATE_AUTH_CORPORATE_URL`, `PRIVATE_AUTH_SERVICE_URL`, `PRIVATE_AUTH_STAFF_URL`,
  `PRIVATE_BASE_CORPORATE_URL`, `PRIVATE_BASE_DEVELOPER_URL`, `PRIVATE_BASE_NETWORK_URL`,
  `PRIVATE_BASE_SERVICE_URL`, `PRIVATE_BASE_STAFF_URL`, `PRIVATE_CORE_CORPORATE_URL`,
  `PRIVATE_CORE_DEVELOPER_URL`, `PRIVATE_CORE_SERVICE_URL`, `PRIVATE_CORE_STAFF_URL`,
  `PRIVATE_GUID_SERVICE_URL`, `PRIVATE_PALM_SERVICE_URL`, `PRIVATE_PERFORMANCE_URL`,
  `PRIVATE_TECH_STAFF_URL`, `PRIVATE_VISA_CORPORATE_URL`, `PRIVATE_VISA_SERVICE_URL`,
  `PRIVATE_VISA_STAFF_URL`, `PUBLIC_AUTH_CORPORATE_URL`, `PUBLIC_BASE_DEVELOPER_URL`,
  `PUBLIC_BLAZER_URL`, `PUBLIC_CORE_CORPORATE_URL`, `PUBLIC_CORE_DEVELOPER_URL`,
  `PUBLIC_CORE_SERVICE_URL`, `PUBLIC_CORE_STAFF_URL`, `PUBLIC_EDGE_CORPORATE_URL`,
  `PUBLIC_EDGE_SERVICE_URL`, `PUBLIC_EDGE_STAFF_URL`, `PUBLIC_FLIPPER_URL`, `PUBLIC_COVERBAND_URL`,
  `PUBLIC_MISSION_URL`, `PUBLIC_PALM_SERVICE_URL`, `PUBLIC_PERFORMANCE_URL`, `PUBLIC_PGHERO_URL`,
  `PUBLIC_STATUS_URL`, `PUBLIC_SWAGGER_URL`, `PUBLIC_TECH_STAFF_URL`, `PUBLIC_VISA_CORPORATE_URL`,
  `PUBLIC_WARP_CORPORATE_URL`, `PUBLIC_WARP_SERVICE_URL`, and `PUBLIC_WARP_STAFF_URL`. Compose
  development-variable names removed in that hard reset were `ALLOY_OTLP_HTTP_HOST_PORT`,
  `CLOUDFLARED_EDGE_TOKEN`, `FAKECLOUD_HOST_PORT`, `GRAFANA_HOST_PORT`,
  `POSTGRESQL_PRIMARY_HOST_PORT`, `POSTGRESQL_REPLICA_HOST_PORT`, `VALKEY_CACHE_HOST_PORT`,
  `VALKEY_HOST_PORT`, and `VALKEY_KVS_HOST_PORT`. `.github/workflows/ci.yml` still contains some
  retired key names because the `.github` mount was read-only;
  `evidence/2026-11-10-surface-hard-reset-A7K2.md` records that remaining name list. Values are
  omitted. The `.com` corporate URL readers remain by owner direction.

### Cumulative deletion footprint

The worktree was dirty before this task. Counts below reflect the current cumulative `git diff HEAD`
and are not attributed only to Round 2.

| Path group               | Deleted paths |
| ------------------------ | ------------: |
| `app/controllers/**`     |           794 |
| `app/views/**`           |           126 |
| `app/helpers/**`         |             6 |
| `config/routes/**`       |             9 |
| `app/adapters/**`        |            32 |
| `app/consumers/**`       |             7 |
| `app/operations/**`      |           134 |
| `app/services/**`        |           108 |
| `app/values/**`          |            70 |
| `app/jobs/**`            |             7 |
| `lib/tasks/**`           |             3 |
| `test/controllers/**`    |           345 |
| `test/integration/**`    |           224 |
| `test/models/**`         |           129 |
| `test/operations/**`     |           133 |
| `test/concurrency/**`    |            31 |
| `test/fixtures/**`       |             9 |
| `test/adapters/**`       |            27 |
| `test/consumers/**`      |             7 |
| `test/services/**`       |           202 |
| `docs/shared/design/**`  |             1 |
| `docs/test-migration/**` |             1 |

The earlier hard-reset evidence records the broader environment-reader, host-list, locale, and
documentation cleanup. No credentials or environment values are recorded here.

### Retained items that look foreign

- Edit's upstream OIDC relying-party integration remains because Edit is an owned RP surface. Press
  has no local Auth sign-in, social sign-in, or OP route.
- `SignOutNoticeStore` remains for Edit RP logout completion as listed above.
- `StepUpAuditDeliveryJob` and its recurring schedule remain to process persisted audit outbox rows,
  even though no current writer produces new rows.
- Social audit delivery and artifact-erasure paths remain only for persisted audit/history handling;
  no provider login entrypoint remains.
- `docs/vendor/identity/` remains as historical vendor-review material. Its README explicitly says
  the old route descriptions are not current Press implementation requirements and points to the
  active README/Edit OIDC boundary; deleting it would erase referenced historical security and audit
  decisions.
- `docs/architecture/op-rp-ownership-manifest.md`, `docs/security/step-up-operation-inventory.md`,
  and the detailed `docs/mermaid/idp-*` transition inventory retain removed controller paths only as
  explicitly dated historical snapshots; their boundary notices distinguish those paths from current
  Press runtime. The dated authentication audits and
  `docs/architecture/auth-ceremony-session-boundary.md` likewise preserve audit/security provenance,
  while the deprecated phase-1 requirements spec now says its former social methods are not current
  Press routes.
- Enforcement and authentication models/services with current model, job, or non-model callers
  remain for the deferred database/model inventory. Stale tests that required unregistered Base/Core
  RP clients were removed; no replacement client was added.
- The hardcoded operator hosts listed above remain at the owner's direction. The four `.com` content
  hosts remain because they are used.
- The `*.core.dev.localhost` host aliases remain only inside the owned operator-tool route
  constraints; README documents them as those tools' local development URLs.

## Part A: baseline and error classification

The preceding hard-reset evidence records the suite before this round as
`9633 runs, 51417 assertions, 117 failures, 2495 errors, 0 skips`; the dirty-worktree run before
that cleanup was `12236 runs, 60950 assertions, 223 failures, 3609 errors, 0 skips`.

The saved baseline trace (`/tmp/surface-hard-reset-final-test.log`) records these cause counts. Its
detailed text contains 2,518 error headings while the Minitest summary reports 2,495 errors; the 23
extra trace headings prevent treating the detail counts as a disjoint sum.

| Cause observed in the saved trace      | Count | Evidence                                                                                                                                                                                                                                                                    |
| -------------------------------------- | ----: | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Fixture foreign-key insertion failures | 1,726 | All traces occur during fixture insertion and report a missing referenced row: `client_step_up_sessions` → `client_tokens` (1,138) and `op_org_grants` → `operator_device_sessions` (588). The saved trace does not distinguish missing fixture rows from fixture ordering. |
| Missing constants/files (`NameError`)  |   421 | Retired/foreign constants reached from tests; the separate name audit found 153 missing constant names across failing tests.                                                                                                                                                |
| Unregistered retired OIDC client IDs   |   272 | Tests attempted Base/Core clients after only the Edit RP client remained registered.                                                                                                                                                                                        |
| `KeyError`                             |    43 | Missing keyed data/configuration in old test paths.                                                                                                                                                                                                                         |
| `NoMethodError`                        |    22 | Unsupported/stale test paths.                                                                                                                                                                                                                                               |
| Other exception classes                |    34 | Includes remote-worker, missing-file, configuration, and argument errors.                                                                                                                                                                                                   |
| Direct missing-translation exception   |     0 | No `I18n::MissingTranslationData` or translation-missing marker was present in the saved trace.                                                                                                                                                                             |

The foreign fixture FK errors and stale Base/Core client errors are absent from the final run. Fixes
removed foreign/retired tests and their fixture dependencies, removed Auth-only concurrency
coverage, removed tests that constructed local Base OP step-up evidence, and corrected the retained
Edit RP tests. No constraint was weakened, no test was skipped, and no placeholder test was added.

## Final full test result and pre-existing red tests

`PARALLEL_WORKERS=1 bin/rails test`: **7593 runs, 53475 assertions, 10 failures, 0 errors, 0
skips**. The ten failures are the same pre-existing failures recorded after the hard reset; the
newly exposed architecture-baseline failure from deleting `TotpWindowConsumer` and
`AuthenticationLogoutAllSessions` was fixed before this final run.

- `RateLimitTest` (6): `test_rails_limiter_emits_a_notification_event`,
  `test_rails_rate_limiter_returns_a_429_problem_document_with_Retry-After_and_RateLimit`,
  `test_distinct_names_in_the_same_controller_do_not_collide`,
  `test_the_response_discloses_neither_the_rule_that_fired_nor_the_enforcing_layer`,
  `test_shared_scope_is_honored_across_controllers`, and
  `test_rails_rate_limiter_returns_html_429_with_plain_message` — temporary integration routes
  return 404 before the rate-limit behavior runs.
- `EnforcementReconciliationJobTest` (2):
  `test_ends_an_active_case_whose_approved_appeal_did_not_finish_ending_it` and
  `test_completes_the_end_audit_for_an_approved_appeal_whose_case_already_ended` — existing
  reconciliation/audit assertions.
- `ObjectPlacementTest#test_every_file_names_its_own_role` — existing naming guard flags
  `app/resolvers/step_up_evidence_verifier.rb`.
- `SecurityHeadersTest#test_content_security_policy_and_permissions_policy_are_enforced` — existing
  test expectation includes a challenge origin absent from the current CSP.

The cleanup exposed and fixed three task-caused test issues: required Edit RP
operator-token/device-session fixtures were restored; `bin/rails architecture:baseline` regenerated
the architecture inventory after earlier identity-graph removals; and the same task was run again
after the final zero-caller cleanup removed two more files listed in that baseline. The architecture
guard then passed: **3 runs, 1132 assertions, 0 failures, 0 errors, 0 skips**. The focused retained
delivery tests passed: **16 runs, 79 assertions, 0 failures, 0 errors, 0 skips**. No database was
dropped; test verification used configured test databases only.

The public-entrypoint inventory, deferred RP table-name invariant, and authentication-context
inventory tests pass within the final full run after their test-only corrections. No constraint was
weakened, no test was skipped, and no placeholder test was added.

## Required checks

| Command                             | Result                                                                                                                                                                                                                                                            |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `bin/rails zeitwerk:check`          | PASS — all is good.                                                                                                                                                                                                                                               |
| `bin/rails routes`                  | PASS — 370 emitted route entries; no foreign host groups and no content-surface root routes.                                                                                                                                                                      |
| `bin/rubocop`                       | PASS — 2692 files inspected, no offenses.                                                                                                                                                                                                                         |
| `bundle exec erb_lint --lint-all`   | PASS — 855 files linted, no errors.                                                                                                                                                                                                                               |
| `bun run check`                     | PASS — format, lint, typecheck and OpenAPI checks passed. The three generated OpenAPI bundle files were already changed relative to HEAD, so only those paths were temporarily staged for `openapi:verify`; they were returned to their unstaged state afterward. |
| `PARALLEL_WORKERS=1 bin/rails test` | FAIL — 7593 runs, 53475 assertions, 10 pre-existing failures, 0 errors, 0 skips; see the failure list above.                                                                                                                                                      |
| `git diff --check`                  | PASS.                                                                                                                                                                                                                                                             |

`bin/rails architecture:baseline` updated the generated architecture baseline after removed files
were no longer present. The architecture baseline test passed afterward. The `.github` mount was
read-only and was not changed; the remaining retired CI variable names are recorded in
`evidence/2026-11-10-surface-hard-reset-A7K2.md`. No `.env*` values were read, printed, or changed
in this round. The earlier host/URL key removals are recorded by name; `.com` corporate URL readers
remain by owner direction. No commit was created, and uncommitted changes affected the results.

## Complete `bin/rails routes` inventory grouped by host-constraint block

Host literals and resolved environment values are omitted. Route rows are grouped by the route-file
host block that owns them. Engine rows are listed once under the tool mount; total counts include
both mount rows and emitted nested engine routes. Coverband emits no route in this run. The
pre-Round-2 route and namespace inventory, with OWN and FOREIGN/RETIRED labels, is retained in
`evidence/2026-11-10-surface-hard-reset-A7K2.md`; the listing below records the final route set.

| Host-constraint block                                |  Routes |
| ---------------------------------------------------- | ------: |
| Docs APP                                             |      10 |
| Docs COM                                             |      10 |
| Docs ORG                                             |      10 |
| News APP                                             |      10 |
| News COM                                             |      10 |
| News ORG                                             |      10 |
| Help APP                                             |      10 |
| Help COM                                             |      10 |
| Help ORG                                             |      10 |
| Info APP                                             |      10 |
| Info COM                                             |      10 |
| Info ORG                                             |      10 |
| Edit ORG                                             |     163 |
| Mission                                              |      25 |
| Flipper                                              |       1 |
| Blazer                                               |      32 |
| PgHero                                               |      26 |
| Swagger                                              |       2 |
| Coverband                                            |       0 |
| Unknown host fallback                                |       1 |
| **Total (mounts plus emitted nested engine routes)** | **370** |

### `config/routes/docs.rb` — APP host block — 10 routes

| Prefix                          | Verb   | Path                                   | Controller / target                     |
| ------------------------------- | ------ | -------------------------------------- | --------------------------------------- |
| `docs_app_revision`             | `GET`  | `/revision`                            | `docs/app/revisions#show`               |
| `docs_app_health`               | `GET`  | `/health`                              | `docs/app/healths#show`                 |
| `docs_app_health_liveness`      | `GET`  | `/health/liveness`                     | `docs/app/health/livenesses#show`       |
| `docs_app_health_readiness`     | `GET`  | `/health/readiness`                    | `docs/app/health/readinesses#show`      |
| `docs_app_health_startup`       | `GET`  | `/health/startup`                      | `docs/app/health/startups#show`         |
| `docs_app_csp_violation_report` | `POST` | `/csp-violation-report(.:format)`      | `docs/app/csp_violation_reports#create` |
| `docs_app_api_v0_entries`       | `GET`  | `/api/v0/entries(.:format)`            | `docs/app/api/v0/entries#index`         |
| `docs_app_api_v0_entry`         | `GET`  | `/api/v0/entries/:public_id(.:format)` | `docs/app/api/v0/entries#show`          |
| `docs_app_api_v0_health`        | `GET`  | `/api/v0/health.json`                  | `docs/app/api/v0/healths#show`          |
| `docs_app_api_v0_revision`      | `GET`  | `/api/v0/revision.json`                | `docs/app/api/v0/revisions#show`        |

### `config/routes/docs.rb` — COM host block — 10 routes

| Prefix                          | Verb   | Path                                   | Controller / target                     |
| ------------------------------- | ------ | -------------------------------------- | --------------------------------------- |
| `docs_com_revision`             | `GET`  | `/revision`                            | `docs/com/revisions#show`               |
| `docs_com_health`               | `GET`  | `/health`                              | `docs/com/healths#show`                 |
| `docs_com_health_liveness`      | `GET`  | `/health/liveness`                     | `docs/com/health/livenesses#show`       |
| `docs_com_health_readiness`     | `GET`  | `/health/readiness`                    | `docs/com/health/readinesses#show`      |
| `docs_com_health_startup`       | `GET`  | `/health/startup`                      | `docs/com/health/startups#show`         |
| `docs_com_csp_violation_report` | `POST` | `/csp-violation-report(.:format)`      | `docs/com/csp_violation_reports#create` |
| `docs_com_api_v0_entries`       | `GET`  | `/api/v0/entries(.:format)`            | `docs/com/api/v0/entries#index`         |
| `docs_com_api_v0_entry`         | `GET`  | `/api/v0/entries/:public_id(.:format)` | `docs/com/api/v0/entries#show`          |
| `docs_com_api_v0_health`        | `GET`  | `/api/v0/health.json`                  | `docs/com/api/v0/healths#show`          |
| `docs_com_api_v0_revision`      | `GET`  | `/api/v0/revision.json`                | `docs/com/api/v0/revisions#show`        |

### `config/routes/docs.rb` — ORG host block — 10 routes

| Prefix                          | Verb   | Path                                   | Controller / target                     |
| ------------------------------- | ------ | -------------------------------------- | --------------------------------------- |
| `docs_org_revision`             | `GET`  | `/revision`                            | `docs/org/revisions#show`               |
| `docs_org_health`               | `GET`  | `/health`                              | `docs/org/healths#show`                 |
| `docs_org_health_liveness`      | `GET`  | `/health/liveness`                     | `docs/org/health/livenesses#show`       |
| `docs_org_health_readiness`     | `GET`  | `/health/readiness`                    | `docs/org/health/readinesses#show`      |
| `docs_org_health_startup`       | `GET`  | `/health/startup`                      | `docs/org/health/startups#show`         |
| `docs_org_csp_violation_report` | `POST` | `/csp-violation-report(.:format)`      | `docs/org/csp_violation_reports#create` |
| `docs_org_api_v0_entries`       | `GET`  | `/api/v0/entries(.:format)`            | `docs/org/api/v0/entries#index`         |
| `docs_org_api_v0_entry`         | `GET`  | `/api/v0/entries/:public_id(.:format)` | `docs/org/api/v0/entries#show`          |
| `docs_org_api_v0_health`        | `GET`  | `/api/v0/health.json`                  | `docs/org/api/v0/healths#show`          |
| `docs_org_api_v0_revision`      | `GET`  | `/api/v0/revision.json`                | `docs/org/api/v0/revisions#show`        |

### `config/routes/news.rb` — APP host block — 10 routes

| Prefix                          | Verb   | Path                                   | Controller / target                     |
| ------------------------------- | ------ | -------------------------------------- | --------------------------------------- |
| `news_app_revision`             | `GET`  | `/revision`                            | `news/app/revisions#show`               |
| `news_app_health`               | `GET`  | `/health`                              | `news/app/healths#show`                 |
| `news_app_health_liveness`      | `GET`  | `/health/liveness`                     | `news/app/health/livenesses#show`       |
| `news_app_health_readiness`     | `GET`  | `/health/readiness`                    | `news/app/health/readinesses#show`      |
| `news_app_health_startup`       | `GET`  | `/health/startup`                      | `news/app/health/startups#show`         |
| `news_app_csp_violation_report` | `POST` | `/csp-violation-report(.:format)`      | `news/app/csp_violation_reports#create` |
| `news_app_api_v0_entries`       | `GET`  | `/api/v0/entries(.:format)`            | `news/app/api/v0/entries#index`         |
| `news_app_api_v0_entry`         | `GET`  | `/api/v0/entries/:public_id(.:format)` | `news/app/api/v0/entries#show`          |
| `news_app_api_v0_health`        | `GET`  | `/api/v0/health.json`                  | `news/app/api/v0/healths#show`          |
| `news_app_api_v0_revision`      | `GET`  | `/api/v0/revision.json`                | `news/app/api/v0/revisions#show`        |

### `config/routes/news.rb` — COM host block — 10 routes

| Prefix                          | Verb   | Path                                   | Controller / target                     |
| ------------------------------- | ------ | -------------------------------------- | --------------------------------------- |
| `news_com_revision`             | `GET`  | `/revision`                            | `news/com/revisions#show`               |
| `news_com_health`               | `GET`  | `/health`                              | `news/com/healths#show`                 |
| `news_com_health_liveness`      | `GET`  | `/health/liveness`                     | `news/com/health/livenesses#show`       |
| `news_com_health_readiness`     | `GET`  | `/health/readiness`                    | `news/com/health/readinesses#show`      |
| `news_com_health_startup`       | `GET`  | `/health/startup`                      | `news/com/health/startups#show`         |
| `news_com_csp_violation_report` | `POST` | `/csp-violation-report(.:format)`      | `news/com/csp_violation_reports#create` |
| `news_com_api_v0_entries`       | `GET`  | `/api/v0/entries(.:format)`            | `news/com/api/v0/entries#index`         |
| `news_com_api_v0_entry`         | `GET`  | `/api/v0/entries/:public_id(.:format)` | `news/com/api/v0/entries#show`          |
| `news_com_api_v0_health`        | `GET`  | `/api/v0/health.json`                  | `news/com/api/v0/healths#show`          |
| `news_com_api_v0_revision`      | `GET`  | `/api/v0/revision.json`                | `news/com/api/v0/revisions#show`        |

### `config/routes/news.rb` — ORG host block — 10 routes

| Prefix                          | Verb   | Path                                   | Controller / target                     |
| ------------------------------- | ------ | -------------------------------------- | --------------------------------------- |
| `news_org_revision`             | `GET`  | `/revision`                            | `news/org/revisions#show`               |
| `news_org_health`               | `GET`  | `/health`                              | `news/org/healths#show`                 |
| `news_org_health_liveness`      | `GET`  | `/health/liveness`                     | `news/org/health/livenesses#show`       |
| `news_org_health_readiness`     | `GET`  | `/health/readiness`                    | `news/org/health/readinesses#show`      |
| `news_org_health_startup`       | `GET`  | `/health/startup`                      | `news/org/health/startups#show`         |
| `news_org_csp_violation_report` | `POST` | `/csp-violation-report(.:format)`      | `news/org/csp_violation_reports#create` |
| `news_org_api_v0_entries`       | `GET`  | `/api/v0/entries(.:format)`            | `news/org/api/v0/entries#index`         |
| `news_org_api_v0_entry`         | `GET`  | `/api/v0/entries/:public_id(.:format)` | `news/org/api/v0/entries#show`          |
| `news_org_api_v0_health`        | `GET`  | `/api/v0/health.json`                  | `news/org/api/v0/healths#show`          |
| `news_org_api_v0_revision`      | `GET`  | `/api/v0/revision.json`                | `news/org/api/v0/revisions#show`        |

### `config/routes/help.rb` — APP host block — 10 routes

| Prefix                          | Verb   | Path                                   | Controller / target                     |
| ------------------------------- | ------ | -------------------------------------- | --------------------------------------- |
| `help_app_revision`             | `GET`  | `/revision`                            | `help/app/revisions#show`               |
| `help_app_health`               | `GET`  | `/health`                              | `help/app/healths#show`                 |
| `help_app_health_liveness`      | `GET`  | `/health/liveness`                     | `help/app/health/livenesses#show`       |
| `help_app_health_readiness`     | `GET`  | `/health/readiness`                    | `help/app/health/readinesses#show`      |
| `help_app_health_startup`       | `GET`  | `/health/startup`                      | `help/app/health/startups#show`         |
| `help_app_csp_violation_report` | `POST` | `/csp-violation-report(.:format)`      | `help/app/csp_violation_reports#create` |
| `help_app_api_v0_entries`       | `GET`  | `/api/v0/entries(.:format)`            | `help/app/api/v0/entries#index`         |
| `help_app_api_v0_entry`         | `GET`  | `/api/v0/entries/:public_id(.:format)` | `help/app/api/v0/entries#show`          |
| `help_app_api_v0_health`        | `GET`  | `/api/v0/health.json`                  | `help/app/api/v0/healths#show`          |
| `help_app_api_v0_revision`      | `GET`  | `/api/v0/revision.json`                | `help/app/api/v0/revisions#show`        |

### `config/routes/help.rb` — COM host block — 10 routes

| Prefix                          | Verb   | Path                                   | Controller / target                     |
| ------------------------------- | ------ | -------------------------------------- | --------------------------------------- |
| `help_com_revision`             | `GET`  | `/revision`                            | `help/com/revisions#show`               |
| `help_com_health`               | `GET`  | `/health`                              | `help/com/healths#show`                 |
| `help_com_health_liveness`      | `GET`  | `/health/liveness`                     | `help/com/health/livenesses#show`       |
| `help_com_health_readiness`     | `GET`  | `/health/readiness`                    | `help/com/health/readinesses#show`      |
| `help_com_health_startup`       | `GET`  | `/health/startup`                      | `help/com/health/startups#show`         |
| `help_com_csp_violation_report` | `POST` | `/csp-violation-report(.:format)`      | `help/com/csp_violation_reports#create` |
| `help_com_api_v0_entries`       | `GET`  | `/api/v0/entries(.:format)`            | `help/com/api/v0/entries#index`         |
| `help_com_api_v0_entry`         | `GET`  | `/api/v0/entries/:public_id(.:format)` | `help/com/api/v0/entries#show`          |
| `help_com_api_v0_health`        | `GET`  | `/api/v0/health.json`                  | `help/com/api/v0/healths#show`          |
| `help_com_api_v0_revision`      | `GET`  | `/api/v0/revision.json`                | `help/com/api/v0/revisions#show`        |

### `config/routes/help.rb` — ORG host block — 10 routes

| Prefix                          | Verb   | Path                                   | Controller / target                     |
| ------------------------------- | ------ | -------------------------------------- | --------------------------------------- |
| `help_org_revision`             | `GET`  | `/revision`                            | `help/org/revisions#show`               |
| `help_org_health`               | `GET`  | `/health`                              | `help/org/healths#show`                 |
| `help_org_health_liveness`      | `GET`  | `/health/liveness`                     | `help/org/health/livenesses#show`       |
| `help_org_health_readiness`     | `GET`  | `/health/readiness`                    | `help/org/health/readinesses#show`      |
| `help_org_health_startup`       | `GET`  | `/health/startup`                      | `help/org/health/startups#show`         |
| `help_org_csp_violation_report` | `POST` | `/csp-violation-report(.:format)`      | `help/org/csp_violation_reports#create` |
| `help_org_api_v0_entries`       | `GET`  | `/api/v0/entries(.:format)`            | `help/org/api/v0/entries#index`         |
| `help_org_api_v0_entry`         | `GET`  | `/api/v0/entries/:public_id(.:format)` | `help/org/api/v0/entries#show`          |
| `help_org_api_v0_health`        | `GET`  | `/api/v0/health.json`                  | `help/org/api/v0/healths#show`          |
| `help_org_api_v0_revision`      | `GET`  | `/api/v0/revision.json`                | `help/org/api/v0/revisions#show`        |

### `config/routes/info.rb` — APP host block — 10 routes

| Prefix                          | Verb   | Path                                   | Controller / target                     |
| ------------------------------- | ------ | -------------------------------------- | --------------------------------------- |
| `info_app_revision`             | `GET`  | `/revision`                            | `info/app/revisions#show`               |
| `info_app_health`               | `GET`  | `/health`                              | `info/app/healths#show`                 |
| `info_app_health_liveness`      | `GET`  | `/health/liveness`                     | `info/app/health/livenesses#show`       |
| `info_app_health_readiness`     | `GET`  | `/health/readiness`                    | `info/app/health/readinesses#show`      |
| `info_app_health_startup`       | `GET`  | `/health/startup`                      | `info/app/health/startups#show`         |
| `info_app_csp_violation_report` | `POST` | `/csp-violation-report(.:format)`      | `info/app/csp_violation_reports#create` |
| `info_app_api_v0_entries`       | `GET`  | `/api/v0/entries(.:format)`            | `info/app/api/v0/entries#index`         |
| `info_app_api_v0_entry`         | `GET`  | `/api/v0/entries/:public_id(.:format)` | `info/app/api/v0/entries#show`          |
| `info_app_api_v0_health`        | `GET`  | `/api/v0/health.json`                  | `info/app/api/v0/healths#show`          |
| `info_app_api_v0_revision`      | `GET`  | `/api/v0/revision.json`                | `info/app/api/v0/revisions#show`        |

### `config/routes/info.rb` — COM host block — 10 routes

| Prefix                          | Verb   | Path                                   | Controller / target                     |
| ------------------------------- | ------ | -------------------------------------- | --------------------------------------- |
| `info_com_revision`             | `GET`  | `/revision`                            | `info/com/revisions#show`               |
| `info_com_health`               | `GET`  | `/health`                              | `info/com/healths#show`                 |
| `info_com_health_liveness`      | `GET`  | `/health/liveness`                     | `info/com/health/livenesses#show`       |
| `info_com_health_readiness`     | `GET`  | `/health/readiness`                    | `info/com/health/readinesses#show`      |
| `info_com_health_startup`       | `GET`  | `/health/startup`                      | `info/com/health/startups#show`         |
| `info_com_csp_violation_report` | `POST` | `/csp-violation-report(.:format)`      | `info/com/csp_violation_reports#create` |
| `info_com_api_v0_entries`       | `GET`  | `/api/v0/entries(.:format)`            | `info/com/api/v0/entries#index`         |
| `info_com_api_v0_entry`         | `GET`  | `/api/v0/entries/:public_id(.:format)` | `info/com/api/v0/entries#show`          |
| `info_com_api_v0_health`        | `GET`  | `/api/v0/health.json`                  | `info/com/api/v0/healths#show`          |
| `info_com_api_v0_revision`      | `GET`  | `/api/v0/revision.json`                | `info/com/api/v0/revisions#show`        |

### `config/routes/info.rb` — ORG host block — 10 routes

| Prefix                          | Verb   | Path                                   | Controller / target                     |
| ------------------------------- | ------ | -------------------------------------- | --------------------------------------- |
| `info_org_revision`             | `GET`  | `/revision`                            | `info/org/revisions#show`               |
| `info_org_health`               | `GET`  | `/health`                              | `info/org/healths#show`                 |
| `info_org_health_liveness`      | `GET`  | `/health/liveness`                     | `info/org/health/livenesses#show`       |
| `info_org_health_readiness`     | `GET`  | `/health/readiness`                    | `info/org/health/readinesses#show`      |
| `info_org_health_startup`       | `GET`  | `/health/startup`                      | `info/org/health/startups#show`         |
| `info_org_csp_violation_report` | `POST` | `/csp-violation-report(.:format)`      | `info/org/csp_violation_reports#create` |
| `info_org_api_v0_entries`       | `GET`  | `/api/v0/entries(.:format)`            | `info/org/api/v0/entries#index`         |
| `info_org_api_v0_entry`         | `GET`  | `/api/v0/entries/:public_id(.:format)` | `info/org/api/v0/entries#show`          |
| `info_org_api_v0_health`        | `GET`  | `/api/v0/health.json`                  | `info/org/api/v0/healths#show`          |
| `info_org_api_v0_revision`      | `GET`  | `/api/v0/revision.json`                | `info/org/api/v0/revisions#show`        |

### `config/routes/edit.rb` — ORG host block — 163 routes

| Prefix                                            | Verb     | Path                                                                                                     | Controller / target                                              |
| ------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `edit_org_root`                                   | `GET`    | `/`                                                                                                      | `edit/org/roots#index`                                           |
| `edit_org_dashboard`                              | `GET`    | `/dashboard(.:format)`                                                                                   | `edit/org/dashboards#show`                                       |
| `edit_org_revision`                               | `GET`    | `/revision`                                                                                              | `edit/org/revisions#show`                                        |
| `edit_org_health`                                 | `GET`    | `/health`                                                                                                | `edit/org/healths#show`                                          |
| `edit_org_health_liveness`                        | `GET`    | `/health/liveness`                                                                                       | `edit/org/health/livenesses#show`                                |
| `edit_org_health_readiness`                       | `GET`    | `/health/readiness`                                                                                      | `edit/org/health/readinesses#show`                               |
| `edit_org_health_startup`                         | `GET`    | `/health/startup`                                                                                        | `edit/org/health/startups#show`                                  |
| `edit_org_csp_violation_report`                   | `POST`   | `/csp-violation-report(.:format)`                                                                        | `edit/org/csp_violation_reports#create`                          |
| `edit_org_api_v0_health`                          | `GET`    | `/api/v0/health.json`                                                                                    | `edit/org/api/v0/healths#show`                                   |
| `edit_org_api_v0_revision`                        | `GET`    | `/api/v0/revision.json`                                                                                  | `edit/org/api/v0/revisions#show`                                 |
| `edit_org_api_v0_publishing_entry_publications`   | `POST`   | `/api/v0/publishing/:surface/:audience/entries/:entry_entry_ref/publications(.:format)`                  | `edit/org/api/v0/publishing/publications#create {surface: /docs  | help | info | news/, audience: /app | com | org/}` |
| `edit_org_api_v0_publishing_entry_publication`    | `DELETE` | `/api/v0/publishing/:surface/:audience/entries/:entry_entry_ref/publications/:publication_ref(.:format)` | `edit/org/api/v0/publishing/publications#destroy {surface: /docs | help | info | news/, audience: /app | com | org/}` |
| `edit_org_api_v0_publishing_entry_archive`        | `DELETE` | `/api/v0/publishing/:surface/:audience/entries/:entry_entry_ref/archive(.:format)`                       | `edit/org/api/v0/publishing/archives#destroy {surface: /docs     | help | info | news/, audience: /app | com | org/}` |
| ``                                                | `POST`   | `/api/v0/publishing/:surface/:audience/entries/:entry_entry_ref/archive(.:format)`                       | `edit/org/api/v0/publishing/archives#create {surface: /docs      | help | info | news/, audience: /app | com | org/}` |
| `edit_org_api_v0_publishing_entries`              | `GET`    | `/api/v0/publishing/:surface/:audience/entries(.:format)`                                                | `edit/org/api/v0/publishing/entries#index {surface: /docs        | help | info | news/, audience: /app | com | org/}` |
| ``                                                | `POST`   | `/api/v0/publishing/:surface/:audience/entries(.:format)`                                                | `edit/org/api/v0/publishing/entries#create {surface: /docs       | help | info | news/, audience: /app | com | org/}` |
| `edit_org_api_v0_publishing_entry`                | `GET`    | `/api/v0/publishing/:surface/:audience/entries/:entry_ref(.:format)`                                     | `edit/org/api/v0/publishing/entries#show {surface: /docs         | help | info | news/, audience: /app | com | org/}` |
| ``                                                | `PATCH`  | `/api/v0/publishing/:surface/:audience/entries/:entry_ref(.:format)`                                     | `edit/org/api/v0/publishing/entries#update {surface: /docs       | help | info | news/, audience: /app | com | org/}` |
| ``                                                | `PUT`    | `/api/v0/publishing/:surface/:audience/entries/:entry_ref(.:format)`                                     | `edit/org/api/v0/publishing/entries#update {surface: /docs       | help | info | news/, audience: /app | com | org/}` |
| `edit_org_oidc_callback`                          | `GET`    | `/oidc/callback(.:format)`                                                                               | `edit/org/oidc/callbacks#show`                                   |
| `edit_org_oidc_closures`                          | `POST`   | `/oidc/closures(.:format)`                                                                               | `edit/org/oidc/closures#create`                                  |
| `edit_org_verification`                           | `GET`    | `/verification(.:format)`                                                                                | `edit/org/verifications#show`                                    |
| ``                                                | `POST`   | `/verification(.:format)`                                                                                | `edit/org/verifications#create`                                  |
| `edit_org_sign_show`                              | `GET`    | `/sign(.:format)`                                                                                        | `edit/org/sign/entries#show`                                     |
| `edit_org_sign_create`                            | `POST`   | `/sign(.:format)`                                                                                        | `edit/org/sign/entries#create`                                   |
| `edit_org_sign_interruption`                      | `GET`    | `/sign/interruption(.:format)`                                                                           | `edit/org/sign/interruptions#show`                               |
| `new_edit_org_sign_out`                           | `GET`    | `/sign/out/new(.:format)`                                                                                | `edit/org/sign/outs#new`                                         |
| `edit_edit_org_sign_out`                          | `GET`    | `/sign/out/edit(.:format)`                                                                               | `edit/org/sign/outs#edit`                                        |
| `edit_org_sign_out`                               | `GET`    | `/sign/out(.:format)`                                                                                    | `edit/org/sign/outs#show`                                        |
| ``                                                | `POST`   | `/sign/out(.:format)`                                                                                    | `edit/org/sign/outs#create`                                      |
| `edit_org_sign_out_completion`                    | `GET`    | `/sign/out/completion(.:format)`                                                                         | `edit/org/sign/outs#show`                                        |
| `edit_org_publishing_info_app_entry_publications` | `POST`   | `/publishing/info/app/entries/:entry_id/publications(.:format)`                                          | `edit/org/publishing/info/app/entries/publications#create`       |
| `edit_org_publishing_info_app_entry_publication`  | `DELETE` | `/publishing/info/app/entries/:entry_id/publications/:id(.:format)`                                      | `edit/org/publishing/info/app/entries/publications#destroy`      |
| `edit_org_publishing_info_app_entry_archive`      | `DELETE` | `/publishing/info/app/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/info/app/entries/archives#destroy`          |
| ``                                                | `POST`   | `/publishing/info/app/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/info/app/entries/archives#create`           |
| `edit_org_publishing_info_app_entries`            | `GET`    | `/publishing/info/app/entries(.:format)`                                                                 | `edit/org/publishing/info/app/entries#index`                     |
| ``                                                | `POST`   | `/publishing/info/app/entries(.:format)`                                                                 | `edit/org/publishing/info/app/entries#create`                    |
| `new_edit_org_publishing_info_app_entry`          | `GET`    | `/publishing/info/app/entries/new(.:format)`                                                             | `edit/org/publishing/info/app/entries#new`                       |
| `edit_edit_org_publishing_info_app_entry`         | `GET`    | `/publishing/info/app/entries/:id/edit(.:format)`                                                        | `edit/org/publishing/info/app/entries#edit`                      |
| `edit_org_publishing_info_app_entry`              | `GET`    | `/publishing/info/app/entries/:id(.:format)`                                                             | `edit/org/publishing/info/app/entries#show`                      |
| ``                                                | `PATCH`  | `/publishing/info/app/entries/:id(.:format)`                                                             | `edit/org/publishing/info/app/entries#update`                    |
| ``                                                | `PUT`    | `/publishing/info/app/entries/:id(.:format)`                                                             | `edit/org/publishing/info/app/entries#update`                    |
| `edit_org_publishing_info_com_entry_publications` | `POST`   | `/publishing/info/com/entries/:entry_id/publications(.:format)`                                          | `edit/org/publishing/info/com/entries/publications#create`       |
| `edit_org_publishing_info_com_entry_publication`  | `DELETE` | `/publishing/info/com/entries/:entry_id/publications/:id(.:format)`                                      | `edit/org/publishing/info/com/entries/publications#destroy`      |
| `edit_org_publishing_info_com_entry_archive`      | `DELETE` | `/publishing/info/com/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/info/com/entries/archives#destroy`          |
| ``                                                | `POST`   | `/publishing/info/com/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/info/com/entries/archives#create`           |
| `edit_org_publishing_info_com_entries`            | `GET`    | `/publishing/info/com/entries(.:format)`                                                                 | `edit/org/publishing/info/com/entries#index`                     |
| ``                                                | `POST`   | `/publishing/info/com/entries(.:format)`                                                                 | `edit/org/publishing/info/com/entries#create`                    |
| `new_edit_org_publishing_info_com_entry`          | `GET`    | `/publishing/info/com/entries/new(.:format)`                                                             | `edit/org/publishing/info/com/entries#new`                       |
| `edit_edit_org_publishing_info_com_entry`         | `GET`    | `/publishing/info/com/entries/:id/edit(.:format)`                                                        | `edit/org/publishing/info/com/entries#edit`                      |
| `edit_org_publishing_info_com_entry`              | `GET`    | `/publishing/info/com/entries/:id(.:format)`                                                             | `edit/org/publishing/info/com/entries#show`                      |
| ``                                                | `PATCH`  | `/publishing/info/com/entries/:id(.:format)`                                                             | `edit/org/publishing/info/com/entries#update`                    |
| ``                                                | `PUT`    | `/publishing/info/com/entries/:id(.:format)`                                                             | `edit/org/publishing/info/com/entries#update`                    |
| `edit_org_publishing_info_org_entry_publications` | `POST`   | `/publishing/info/org/entries/:entry_id/publications(.:format)`                                          | `edit/org/publishing/info/org/entries/publications#create`       |
| `edit_org_publishing_info_org_entry_publication`  | `DELETE` | `/publishing/info/org/entries/:entry_id/publications/:id(.:format)`                                      | `edit/org/publishing/info/org/entries/publications#destroy`      |
| `edit_org_publishing_info_org_entry_archive`      | `DELETE` | `/publishing/info/org/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/info/org/entries/archives#destroy`          |
| ``                                                | `POST`   | `/publishing/info/org/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/info/org/entries/archives#create`           |
| `edit_org_publishing_info_org_entries`            | `GET`    | `/publishing/info/org/entries(.:format)`                                                                 | `edit/org/publishing/info/org/entries#index`                     |
| ``                                                | `POST`   | `/publishing/info/org/entries(.:format)`                                                                 | `edit/org/publishing/info/org/entries#create`                    |
| `new_edit_org_publishing_info_org_entry`          | `GET`    | `/publishing/info/org/entries/new(.:format)`                                                             | `edit/org/publishing/info/org/entries#new`                       |
| `edit_edit_org_publishing_info_org_entry`         | `GET`    | `/publishing/info/org/entries/:id/edit(.:format)`                                                        | `edit/org/publishing/info/org/entries#edit`                      |
| `edit_org_publishing_info_org_entry`              | `GET`    | `/publishing/info/org/entries/:id(.:format)`                                                             | `edit/org/publishing/info/org/entries#show`                      |
| ``                                                | `PATCH`  | `/publishing/info/org/entries/:id(.:format)`                                                             | `edit/org/publishing/info/org/entries#update`                    |
| ``                                                | `PUT`    | `/publishing/info/org/entries/:id(.:format)`                                                             | `edit/org/publishing/info/org/entries#update`                    |
| `edit_org_publishing_docs_app_entry_publications` | `POST`   | `/publishing/docs/app/entries/:entry_id/publications(.:format)`                                          | `edit/org/publishing/docs/app/entries/publications#create`       |
| `edit_org_publishing_docs_app_entry_publication`  | `DELETE` | `/publishing/docs/app/entries/:entry_id/publications/:id(.:format)`                                      | `edit/org/publishing/docs/app/entries/publications#destroy`      |
| `edit_org_publishing_docs_app_entry_archive`      | `DELETE` | `/publishing/docs/app/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/docs/app/entries/archives#destroy`          |
| ``                                                | `POST`   | `/publishing/docs/app/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/docs/app/entries/archives#create`           |
| `edit_org_publishing_docs_app_entries`            | `GET`    | `/publishing/docs/app/entries(.:format)`                                                                 | `edit/org/publishing/docs/app/entries#index`                     |
| ``                                                | `POST`   | `/publishing/docs/app/entries(.:format)`                                                                 | `edit/org/publishing/docs/app/entries#create`                    |
| `new_edit_org_publishing_docs_app_entry`          | `GET`    | `/publishing/docs/app/entries/new(.:format)`                                                             | `edit/org/publishing/docs/app/entries#new`                       |
| `edit_edit_org_publishing_docs_app_entry`         | `GET`    | `/publishing/docs/app/entries/:id/edit(.:format)`                                                        | `edit/org/publishing/docs/app/entries#edit`                      |
| `edit_org_publishing_docs_app_entry`              | `GET`    | `/publishing/docs/app/entries/:id(.:format)`                                                             | `edit/org/publishing/docs/app/entries#show`                      |
| ``                                                | `PATCH`  | `/publishing/docs/app/entries/:id(.:format)`                                                             | `edit/org/publishing/docs/app/entries#update`                    |
| ``                                                | `PUT`    | `/publishing/docs/app/entries/:id(.:format)`                                                             | `edit/org/publishing/docs/app/entries#update`                    |
| `edit_org_publishing_docs_com_entry_publications` | `POST`   | `/publishing/docs/com/entries/:entry_id/publications(.:format)`                                          | `edit/org/publishing/docs/com/entries/publications#create`       |
| `edit_org_publishing_docs_com_entry_publication`  | `DELETE` | `/publishing/docs/com/entries/:entry_id/publications/:id(.:format)`                                      | `edit/org/publishing/docs/com/entries/publications#destroy`      |
| `edit_org_publishing_docs_com_entry_archive`      | `DELETE` | `/publishing/docs/com/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/docs/com/entries/archives#destroy`          |
| ``                                                | `POST`   | `/publishing/docs/com/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/docs/com/entries/archives#create`           |
| `edit_org_publishing_docs_com_entries`            | `GET`    | `/publishing/docs/com/entries(.:format)`                                                                 | `edit/org/publishing/docs/com/entries#index`                     |
| ``                                                | `POST`   | `/publishing/docs/com/entries(.:format)`                                                                 | `edit/org/publishing/docs/com/entries#create`                    |
| `new_edit_org_publishing_docs_com_entry`          | `GET`    | `/publishing/docs/com/entries/new(.:format)`                                                             | `edit/org/publishing/docs/com/entries#new`                       |
| `edit_edit_org_publishing_docs_com_entry`         | `GET`    | `/publishing/docs/com/entries/:id/edit(.:format)`                                                        | `edit/org/publishing/docs/com/entries#edit`                      |
| `edit_org_publishing_docs_com_entry`              | `GET`    | `/publishing/docs/com/entries/:id(.:format)`                                                             | `edit/org/publishing/docs/com/entries#show`                      |
| ``                                                | `PATCH`  | `/publishing/docs/com/entries/:id(.:format)`                                                             | `edit/org/publishing/docs/com/entries#update`                    |
| ``                                                | `PUT`    | `/publishing/docs/com/entries/:id(.:format)`                                                             | `edit/org/publishing/docs/com/entries#update`                    |
| `edit_org_publishing_docs_org_entry_publications` | `POST`   | `/publishing/docs/org/entries/:entry_id/publications(.:format)`                                          | `edit/org/publishing/docs/org/entries/publications#create`       |
| `edit_org_publishing_docs_org_entry_publication`  | `DELETE` | `/publishing/docs/org/entries/:entry_id/publications/:id(.:format)`                                      | `edit/org/publishing/docs/org/entries/publications#destroy`      |
| `edit_org_publishing_docs_org_entry_archive`      | `DELETE` | `/publishing/docs/org/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/docs/org/entries/archives#destroy`          |
| ``                                                | `POST`   | `/publishing/docs/org/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/docs/org/entries/archives#create`           |
| `edit_org_publishing_docs_org_entries`            | `GET`    | `/publishing/docs/org/entries(.:format)`                                                                 | `edit/org/publishing/docs/org/entries#index`                     |
| ``                                                | `POST`   | `/publishing/docs/org/entries(.:format)`                                                                 | `edit/org/publishing/docs/org/entries#create`                    |
| `new_edit_org_publishing_docs_org_entry`          | `GET`    | `/publishing/docs/org/entries/new(.:format)`                                                             | `edit/org/publishing/docs/org/entries#new`                       |
| `edit_edit_org_publishing_docs_org_entry`         | `GET`    | `/publishing/docs/org/entries/:id/edit(.:format)`                                                        | `edit/org/publishing/docs/org/entries#edit`                      |
| `edit_org_publishing_docs_org_entry`              | `GET`    | `/publishing/docs/org/entries/:id(.:format)`                                                             | `edit/org/publishing/docs/org/entries#show`                      |
| ``                                                | `PATCH`  | `/publishing/docs/org/entries/:id(.:format)`                                                             | `edit/org/publishing/docs/org/entries#update`                    |
| ``                                                | `PUT`    | `/publishing/docs/org/entries/:id(.:format)`                                                             | `edit/org/publishing/docs/org/entries#update`                    |
| `edit_org_publishing_news_app_entry_publications` | `POST`   | `/publishing/news/app/entries/:entry_id/publications(.:format)`                                          | `edit/org/publishing/news/app/entries/publications#create`       |
| `edit_org_publishing_news_app_entry_publication`  | `DELETE` | `/publishing/news/app/entries/:entry_id/publications/:id(.:format)`                                      | `edit/org/publishing/news/app/entries/publications#destroy`      |
| `edit_org_publishing_news_app_entry_archive`      | `DELETE` | `/publishing/news/app/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/news/app/entries/archives#destroy`          |
| ``                                                | `POST`   | `/publishing/news/app/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/news/app/entries/archives#create`           |
| `edit_org_publishing_news_app_entries`            | `GET`    | `/publishing/news/app/entries(.:format)`                                                                 | `edit/org/publishing/news/app/entries#index`                     |
| ``                                                | `POST`   | `/publishing/news/app/entries(.:format)`                                                                 | `edit/org/publishing/news/app/entries#create`                    |
| `new_edit_org_publishing_news_app_entry`          | `GET`    | `/publishing/news/app/entries/new(.:format)`                                                             | `edit/org/publishing/news/app/entries#new`                       |
| `edit_edit_org_publishing_news_app_entry`         | `GET`    | `/publishing/news/app/entries/:id/edit(.:format)`                                                        | `edit/org/publishing/news/app/entries#edit`                      |
| `edit_org_publishing_news_app_entry`              | `GET`    | `/publishing/news/app/entries/:id(.:format)`                                                             | `edit/org/publishing/news/app/entries#show`                      |
| ``                                                | `PATCH`  | `/publishing/news/app/entries/:id(.:format)`                                                             | `edit/org/publishing/news/app/entries#update`                    |
| ``                                                | `PUT`    | `/publishing/news/app/entries/:id(.:format)`                                                             | `edit/org/publishing/news/app/entries#update`                    |
| `edit_org_publishing_news_com_entry_publications` | `POST`   | `/publishing/news/com/entries/:entry_id/publications(.:format)`                                          | `edit/org/publishing/news/com/entries/publications#create`       |
| `edit_org_publishing_news_com_entry_publication`  | `DELETE` | `/publishing/news/com/entries/:entry_id/publications/:id(.:format)`                                      | `edit/org/publishing/news/com/entries/publications#destroy`      |
| `edit_org_publishing_news_com_entry_archive`      | `DELETE` | `/publishing/news/com/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/news/com/entries/archives#destroy`          |
| ``                                                | `POST`   | `/publishing/news/com/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/news/com/entries/archives#create`           |
| `edit_org_publishing_news_com_entries`            | `GET`    | `/publishing/news/com/entries(.:format)`                                                                 | `edit/org/publishing/news/com/entries#index`                     |
| ``                                                | `POST`   | `/publishing/news/com/entries(.:format)`                                                                 | `edit/org/publishing/news/com/entries#create`                    |
| `new_edit_org_publishing_news_com_entry`          | `GET`    | `/publishing/news/com/entries/new(.:format)`                                                             | `edit/org/publishing/news/com/entries#new`                       |
| `edit_edit_org_publishing_news_com_entry`         | `GET`    | `/publishing/news/com/entries/:id/edit(.:format)`                                                        | `edit/org/publishing/news/com/entries#edit`                      |
| `edit_org_publishing_news_com_entry`              | `GET`    | `/publishing/news/com/entries/:id(.:format)`                                                             | `edit/org/publishing/news/com/entries#show`                      |
| ``                                                | `PATCH`  | `/publishing/news/com/entries/:id(.:format)`                                                             | `edit/org/publishing/news/com/entries#update`                    |
| ``                                                | `PUT`    | `/publishing/news/com/entries/:id(.:format)`                                                             | `edit/org/publishing/news/com/entries#update`                    |
| `edit_org_publishing_news_org_entry_publications` | `POST`   | `/publishing/news/org/entries/:entry_id/publications(.:format)`                                          | `edit/org/publishing/news/org/entries/publications#create`       |
| `edit_org_publishing_news_org_entry_publication`  | `DELETE` | `/publishing/news/org/entries/:entry_id/publications/:id(.:format)`                                      | `edit/org/publishing/news/org/entries/publications#destroy`      |
| `edit_org_publishing_news_org_entry_archive`      | `DELETE` | `/publishing/news/org/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/news/org/entries/archives#destroy`          |
| ``                                                | `POST`   | `/publishing/news/org/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/news/org/entries/archives#create`           |
| `edit_org_publishing_news_org_entries`            | `GET`    | `/publishing/news/org/entries(.:format)`                                                                 | `edit/org/publishing/news/org/entries#index`                     |
| ``                                                | `POST`   | `/publishing/news/org/entries(.:format)`                                                                 | `edit/org/publishing/news/org/entries#create`                    |
| `new_edit_org_publishing_news_org_entry`          | `GET`    | `/publishing/news/org/entries/new(.:format)`                                                             | `edit/org/publishing/news/org/entries#new`                       |
| `edit_edit_org_publishing_news_org_entry`         | `GET`    | `/publishing/news/org/entries/:id/edit(.:format)`                                                        | `edit/org/publishing/news/org/entries#edit`                      |
| `edit_org_publishing_news_org_entry`              | `GET`    | `/publishing/news/org/entries/:id(.:format)`                                                             | `edit/org/publishing/news/org/entries#show`                      |
| ``                                                | `PATCH`  | `/publishing/news/org/entries/:id(.:format)`                                                             | `edit/org/publishing/news/org/entries#update`                    |
| ``                                                | `PUT`    | `/publishing/news/org/entries/:id(.:format)`                                                             | `edit/org/publishing/news/org/entries#update`                    |
| `edit_org_publishing_help_app_entry_publications` | `POST`   | `/publishing/help/app/entries/:entry_id/publications(.:format)`                                          | `edit/org/publishing/help/app/entries/publications#create`       |
| `edit_org_publishing_help_app_entry_publication`  | `DELETE` | `/publishing/help/app/entries/:entry_id/publications/:id(.:format)`                                      | `edit/org/publishing/help/app/entries/publications#destroy`      |
| `edit_org_publishing_help_app_entry_archive`      | `DELETE` | `/publishing/help/app/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/help/app/entries/archives#destroy`          |
| ``                                                | `POST`   | `/publishing/help/app/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/help/app/entries/archives#create`           |
| `edit_org_publishing_help_app_entries`            | `GET`    | `/publishing/help/app/entries(.:format)`                                                                 | `edit/org/publishing/help/app/entries#index`                     |
| ``                                                | `POST`   | `/publishing/help/app/entries(.:format)`                                                                 | `edit/org/publishing/help/app/entries#create`                    |
| `new_edit_org_publishing_help_app_entry`          | `GET`    | `/publishing/help/app/entries/new(.:format)`                                                             | `edit/org/publishing/help/app/entries#new`                       |
| `edit_edit_org_publishing_help_app_entry`         | `GET`    | `/publishing/help/app/entries/:id/edit(.:format)`                                                        | `edit/org/publishing/help/app/entries#edit`                      |
| `edit_org_publishing_help_app_entry`              | `GET`    | `/publishing/help/app/entries/:id(.:format)`                                                             | `edit/org/publishing/help/app/entries#show`                      |
| ``                                                | `PATCH`  | `/publishing/help/app/entries/:id(.:format)`                                                             | `edit/org/publishing/help/app/entries#update`                    |
| ``                                                | `PUT`    | `/publishing/help/app/entries/:id(.:format)`                                                             | `edit/org/publishing/help/app/entries#update`                    |
| `edit_org_publishing_help_com_entry_publications` | `POST`   | `/publishing/help/com/entries/:entry_id/publications(.:format)`                                          | `edit/org/publishing/help/com/entries/publications#create`       |
| `edit_org_publishing_help_com_entry_publication`  | `DELETE` | `/publishing/help/com/entries/:entry_id/publications/:id(.:format)`                                      | `edit/org/publishing/help/com/entries/publications#destroy`      |
| `edit_org_publishing_help_com_entry_archive`      | `DELETE` | `/publishing/help/com/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/help/com/entries/archives#destroy`          |
| ``                                                | `POST`   | `/publishing/help/com/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/help/com/entries/archives#create`           |
| `edit_org_publishing_help_com_entries`            | `GET`    | `/publishing/help/com/entries(.:format)`                                                                 | `edit/org/publishing/help/com/entries#index`                     |
| ``                                                | `POST`   | `/publishing/help/com/entries(.:format)`                                                                 | `edit/org/publishing/help/com/entries#create`                    |
| `new_edit_org_publishing_help_com_entry`          | `GET`    | `/publishing/help/com/entries/new(.:format)`                                                             | `edit/org/publishing/help/com/entries#new`                       |
| `edit_edit_org_publishing_help_com_entry`         | `GET`    | `/publishing/help/com/entries/:id/edit(.:format)`                                                        | `edit/org/publishing/help/com/entries#edit`                      |
| `edit_org_publishing_help_com_entry`              | `GET`    | `/publishing/help/com/entries/:id(.:format)`                                                             | `edit/org/publishing/help/com/entries#show`                      |
| ``                                                | `PATCH`  | `/publishing/help/com/entries/:id(.:format)`                                                             | `edit/org/publishing/help/com/entries#update`                    |
| ``                                                | `PUT`    | `/publishing/help/com/entries/:id(.:format)`                                                             | `edit/org/publishing/help/com/entries#update`                    |
| `edit_org_publishing_help_org_entry_publications` | `POST`   | `/publishing/help/org/entries/:entry_id/publications(.:format)`                                          | `edit/org/publishing/help/org/entries/publications#create`       |
| `edit_org_publishing_help_org_entry_publication`  | `DELETE` | `/publishing/help/org/entries/:entry_id/publications/:id(.:format)`                                      | `edit/org/publishing/help/org/entries/publications#destroy`      |
| `edit_org_publishing_help_org_entry_archive`      | `DELETE` | `/publishing/help/org/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/help/org/entries/archives#destroy`          |
| ``                                                | `POST`   | `/publishing/help/org/entries/:entry_id/archive(.:format)`                                               | `edit/org/publishing/help/org/entries/archives#create`           |
| `edit_org_publishing_help_org_entries`            | `GET`    | `/publishing/help/org/entries(.:format)`                                                                 | `edit/org/publishing/help/org/entries#index`                     |
| ``                                                | `POST`   | `/publishing/help/org/entries(.:format)`                                                                 | `edit/org/publishing/help/org/entries#create`                    |
| `new_edit_org_publishing_help_org_entry`          | `GET`    | `/publishing/help/org/entries/new(.:format)`                                                             | `edit/org/publishing/help/org/entries#new`                       |
| `edit_edit_org_publishing_help_org_entry`         | `GET`    | `/publishing/help/org/entries/:id/edit(.:format)`                                                        | `edit/org/publishing/help/org/entries#edit`                      |
| `edit_org_publishing_help_org_entry`              | `GET`    | `/publishing/help/org/entries/:id(.:format)`                                                             | `edit/org/publishing/help/org/entries#show`                      |
| ``                                                | `PATCH`  | `/publishing/help/org/entries/:id(.:format)`                                                             | `edit/org/publishing/help/org/entries#update`                    |
| ``                                                | `PUT`    | `/publishing/help/org/entries/:id(.:format)`                                                             | `edit/org/publishing/help/org/entries#update`                    |

### `config/routes/mission.rb` host block — 25 routes

| Prefix                        | Verb     | Path                                                             | Controller / target                           |
| ----------------------------- | -------- | ---------------------------------------------------------------- | --------------------------------------------- |
| `mission_control_jobs`        | `MOUNT`  | `/`                                                              | `MissionControl::Jobs::Engine`                |
| `application_queue_pause`     | `DELETE` | `/applications/:application_id/queues/:queue_id/pause(.:format)` | `mission_control/jobs/queues/pauses#destroy`  |
| ``                            | `POST`   | `/applications/:application_id/queues/:queue_id/pause(.:format)` | `mission_control/jobs/queues/pauses#create`   |
| `application_queues`          | `GET`    | `/applications/:application_id/queues(.:format)`                 | `mission_control/jobs/queues#index`           |
| `application_queue`           | `GET`    | `/applications/:application_id/queues/:id(.:format)`             | `mission_control/jobs/queues#show`            |
| `application_job_retry`       | `POST`   | `/applications/:application_id/jobs/:job_id/retry(.:format)`     | `mission_control/jobs/retries#create`         |
| `application_job_discard`     | `POST`   | `/applications/:application_id/jobs/:job_id/discard(.:format)`   | `mission_control/jobs/discards#create`        |
| `application_job_dispatch`    | `POST`   | `/applications/:application_id/jobs/:job_id/dispatch(.:format)`  | `mission_control/jobs/dispatches#create`      |
| `application_bulk_retries`    | `POST`   | `/applications/:application_id/jobs/bulk_retries(.:format)`      | `mission_control/jobs/bulk_retries#create`    |
| `application_bulk_discards`   | `POST`   | `/applications/:application_id/jobs/bulk_discards(.:format)`     | `mission_control/jobs/bulk_discards#create`   |
| `application_job`             | `GET`    | `/applications/:application_id/jobs/:id(.:format)`               | `mission_control/jobs/jobs#show`              |
| `application_jobs`            | `GET`    | `/applications/:application_id/:status/jobs(.:format)`           | `mission_control/jobs/jobs#index`             |
| `application_workers`         | `GET`    | `/applications/:application_id/workers(.:format)`                | `mission_control/jobs/workers#index`          |
| `application_worker`          | `GET`    | `/applications/:application_id/workers/:id(.:format)`            | `mission_control/jobs/workers#show`           |
| `application_recurring_tasks` | `GET`    | `/applications/:application_id/recurring_tasks(.:format)`        | `mission_control/jobs/recurring_tasks#index`  |
| `application_recurring_task`  | `GET`    | `/applications/:application_id/recurring_tasks/:id(.:format)`    | `mission_control/jobs/recurring_tasks#show`   |
| ``                            | `PATCH`  | `/applications/:application_id/recurring_tasks/:id(.:format)`    | `mission_control/jobs/recurring_tasks#update` |
| ``                            | `PUT`    | `/applications/:application_id/recurring_tasks/:id(.:format)`    | `mission_control/jobs/recurring_tasks#update` |
| `application_batches`         | `GET`    | `/applications/:application_id/batches(.:format)`                | `mission_control/jobs/batches#index`          |
| `application_batch`           | `GET`    | `/applications/:application_id/batches/:id(.:format)`            | `mission_control/jobs/batches#show`           |
| `queues`                      | `GET`    | `/queues(.:format)`                                              | `mission_control/jobs/queues#index`           |
| `queue`                       | `GET`    | `/queues/:id(.:format)`                                          | `mission_control/jobs/queues#show`            |
| `job`                         | `GET`    | `/jobs/:id(.:format)`                                            | `mission_control/jobs/jobs#show`              |
| `jobs`                        | `GET`    | `/:status/jobs(.:format)`                                        | `mission_control/jobs/jobs#index`             |
| `root`                        | `GET`    | `/`                                                              | `mission_control/jobs/queues#index`           |

### `config/routes/flipper.rb` host block — 1 routes

| Prefix    | Verb    | Path | Controller / target               |
| --------- | ------- | ---- | --------------------------------- |
| `flipper` | `MOUNT` | `/`  | `Rack::Auth::Basic (Flipper::UI)` |

### `config/routes/blazer.rb` host block — 32 routes

| Prefix              | Verb     | Path                                | Controller / target         |
| ------------------- | -------- | ----------------------------------- | --------------------------- |
| `blazer`            | `MOUNT`  | `/`                                 | `Blazer::Engine`            |
| `run_queries`       | `POST`   | `/queries/run(.:format)`            | `blazer/queries#run`        |
| `cancel_queries`    | `POST`   | `/queries/cancel(.:format)`         | `blazer/queries#cancel`     |
| `refresh_query`     | `POST`   | `/queries/:id/refresh(.:format)`    | `blazer/queries#refresh`    |
| `tables_queries`    | `GET`    | `/queries/tables(.:format)`         | `blazer/queries#tables`     |
| `schema_queries`    | `GET`    | `/queries/schema(.:format)`         | `blazer/queries#schema`     |
| `docs_queries`      | `GET`    | `/queries/docs(.:format)`           | `blazer/queries#docs`       |
| `queries`           | `GET`    | `/queries(.:format)`                | `blazer/queries#index`      |
| ``                  | `POST`   | `/queries(.:format)`                | `blazer/queries#create`     |
| `new_query`         | `GET`    | `/queries/new(.:format)`            | `blazer/queries#new`        |
| `edit_query`        | `GET`    | `/queries/:id/edit(.:format)`       | `blazer/queries#edit`       |
| `query`             | `GET`    | `/queries/:id(.:format)`            | `blazer/queries#show`       |
| ``                  | `PATCH`  | `/queries/:id(.:format)`            | `blazer/queries#update`     |
| ``                  | `PUT`    | `/queries/:id(.:format)`            | `blazer/queries#update`     |
| ``                  | `DELETE` | `/queries/:id(.:format)`            | `blazer/queries#destroy`    |
| `run_check`         | `GET`    | `/checks/:id/run(.:format)`         | `blazer/checks#run`         |
| `checks`            | `GET`    | `/checks(.:format)`                 | `blazer/checks#index`       |
| ``                  | `POST`   | `/checks(.:format)`                 | `blazer/checks#create`      |
| `new_check`         | `GET`    | `/checks/new(.:format)`             | `blazer/checks#new`         |
| `edit_check`        | `GET`    | `/checks/:id/edit(.:format)`        | `blazer/checks#edit`        |
| `check`             | `PATCH`  | `/checks/:id(.:format)`             | `blazer/checks#update`      |
| ``                  | `PUT`    | `/checks/:id(.:format)`             | `blazer/checks#update`      |
| ``                  | `DELETE` | `/checks/:id(.:format)`             | `blazer/checks#destroy`     |
| `refresh_dashboard` | `POST`   | `/dashboards/:id/refresh(.:format)` | `blazer/dashboards#refresh` |
| `dashboards`        | `POST`   | `/dashboards(.:format)`             | `blazer/dashboards#create`  |
| `new_dashboard`     | `GET`    | `/dashboards/new(.:format)`         | `blazer/dashboards#new`     |
| `edit_dashboard`    | `GET`    | `/dashboards/:id/edit(.:format)`    | `blazer/dashboards#edit`    |
| `dashboard`         | `GET`    | `/dashboards/:id(.:format)`         | `blazer/dashboards#show`    |
| ``                  | `PATCH`  | `/dashboards/:id(.:format)`         | `blazer/dashboards#update`  |
| ``                  | `PUT`    | `/dashboards/:id(.:format)`         | `blazer/dashboards#update`  |
| ``                  | `DELETE` | `/dashboards/:id(.:format)`         | `blazer/dashboards#destroy` |
| `root`              | `GET`    | `/`                                 | `blazer/queries#home`       |

### `config/routes/pghero.rb` host block — 26 routes

| Prefix                      | Verb    | Path                                               | Controller / target                      |
| --------------------------- | ------- | -------------------------------------------------- | ---------------------------------------- |
| `pghero`                    | `MOUNT` | `/`                                                | `PgHero::Engine`                         |
| `space`                     | `GET`   | `(/:database)/space(.:format)`                     | `pg_hero/home#space`                     |
| `relation_space`            | `GET`   | `(/:database)/space/:relation(.:format)`           | `pg_hero/home#relation_space`            |
| `index_bloat`               | `GET`   | `(/:database)/index_bloat(.:format)`               | `pg_hero/home#index_bloat`               |
| `live_queries`              | `GET`   | `(/:database)/live_queries(.:format)`              | `pg_hero/home#live_queries`              |
| `queries`                   | `GET`   | `(/:database)/queries(.:format)`                   | `pg_hero/home#queries`                   |
| `show_query`                | `GET`   | `(/:database)/queries/:query_hash(.:format)`       | `pg_hero/home#show_query`                |
| `system`                    | `GET`   | `(/:database)/system(.:format)`                    | `pg_hero/home#system`                    |
| `cpu_usage`                 | `GET`   | `(/:database)/cpu_usage(.:format)`                 | `pg_hero/home#cpu_usage`                 |
| `connection_stats`          | `GET`   | `(/:database)/connection_stats(.:format)`          | `pg_hero/home#connection_stats`          |
| `replication_lag_stats`     | `GET`   | `(/:database)/replication_lag_stats(.:format)`     | `pg_hero/home#replication_lag_stats`     |
| `load_stats`                | `GET`   | `(/:database)/load_stats(.:format)`                | `pg_hero/home#load_stats`                |
| `free_space_stats`          | `GET`   | `(/:database)/free_space_stats(.:format)`          | `pg_hero/home#free_space_stats`          |
| `explain`                   | `GET`   | `(/:database)/explain(.:format)`                   | `pg_hero/home#explain`                   |
| `tune`                      | `GET`   | `(/:database)/tune(.:format)`                      | `pg_hero/home#tune`                      |
| `connections`               | `GET`   | `(/:database)/connections(.:format)`               | `pg_hero/home#connections`               |
| `maintenance`               | `GET`   | `(/:database)/maintenance(.:format)`               | `pg_hero/home#maintenance`               |
| `kill`                      | `POST`  | `(/:database)/kill(.:format)`                      | `pg_hero/home#kill`                      |
| `kill_long_running_queries` | `POST`  | `(/:database)/kill_long_running_queries(.:format)` | `pg_hero/home#kill_long_running_queries` |
| `kill_all`                  | `POST`  | `(/:database)/kill_all(.:format)`                  | `pg_hero/home#kill_all`                  |
| `enable_query_stats`        | `POST`  | `(/:database)/enable_query_stats(.:format)`        | `pg_hero/home#enable_query_stats`        |
| ``                          | `POST`  | `(/:database)/explain(.:format)`                   | `pg_hero/home#explain`                   |
| `reset_query_stats`         | `POST`  | `(/:database)/reset_query_stats(.:format)`         | `pg_hero/home#reset_query_stats`         |
| `system_stats`              | `GET`   | `(/:database)/system_stats(.:format)`              | `redirect(301, system)`                  |
| `query_stats`               | `GET`   | `(/:database)/query_stats(.:format)`               | `redirect(301, queries)`                 |
| `root`                      | `GET`   | `/(:database)(.:format)`                           | `pg_hero/home#index`                     |

### `config/routes/swagger.rb` host block — 2 routes

| Prefix      | Verb    | Path       | Controller / target  |
| ----------- | ------- | ---------- | -------------------- |
| `rswag_api` | `MOUNT` | `/openapi` | `Rswag::Api::Engine` |
| `rswag_ui`  | `MOUNT` | `/`        | `Rswag::Ui::Engine`  |

### `config/routes/coverband.rb` host block — 0 routes

| Prefix | Verb | Path | Controller / target          |
| ------ | ---- | ---- | ---------------------------- |
| —      | —    | —    | No route emitted in this run |

### `config/routes.rb` — unknown-host fallback — 1 routes

| Prefix | Verb  | Path | Controller / target  |
| ------ | ----- | ---- | -------------------- |
| ``     | `GET` | `/`  | `unknown_hosts#show` |

## Abstract Record database/model report (current source scan)

The model inventory itself did not connect to or query databases. The required Rails test suite used
the configured test databases separately. No model or migration file was deleted. Database
configuration values were not read or recorded. The scan uses exact class constants and unique
unqualified names across current Ruby references; it may miss reflection, string dispatch,
fixture-only references, SQL-only use, and framework conventions. This final scan accounts for the
zero-caller code removed below.

| Database      | Abstract Record     | `database.yml` key | Classification      | Runtime models | Model/test only | No static reference |
| ------------- | ------------------- | ------------------ | ------------------- | -------------: | --------------: | ------------------: |
| `app_setting` | `AppSettingRecord`  | PRESENT            | **USED**            |             23 |               5 |                   1 |
| `app_signal`  | `AppSignalRecord`   | PRESENT            | **USED**            |              1 |               1 |                   0 |
| `app_zenith`  | `AppZenithRecord`   | PRESENT            | **USED**            |             60 |              51 |                   3 |
| `avatar`      | `AvatarRecord`      | PRESENT            | **USED**            |             19 |              26 |                   0 |
| `chronicle`   | `ChronicleRecord`   | PRESENT            | **USED**            |             21 |               1 |                   0 |
| `com_setting` | `ComSettingRecord`  | PRESENT            | **USED**            |             27 |               2 |                   0 |
| `occurrence`  | `OccurrenceRecord`  | PRESENT            | **USED**            |             13 |              39 |                   0 |
| `op_base_app` | `OpBaseAppRecord`   | PRESENT            | **USED**            |             36 |              25 |                   4 |
| `op_base_org` | `OpBaseOrgRecord`   | PRESENT            | **USED**            |             30 |              21 |                   2 |
| `org_setting` | `OrgSettingRecord`  | PRESENT            | **USED**            |             23 |               6 |                   0 |
| `org_signal`  | `OrgSignalRecord`   | PRESENT            | **USED**            |              1 |               1 |                   0 |
| `org_zenith`  | `OrgZenithRecord`   | PRESENT            | **USED**            |             52 |              44 |                   1 |
| `publishing`  | `PublishingRecord`  | PRESENT            | **USED**            |             12 |             126 |                  19 |
| `primary`     | `ApplicationRecord` | PRESENT            | **UNUSED**          |              0 |               0 |                   0 |
| `rp_base_app` | `RpBaseAppRecord`   | MISSING            | **USED**            |              3 |               9 |                   1 |
| `rp_base_org` | `RpBaseOrgRecord`   | MISSING            | **USED**            |              3 |              10 |                   1 |
| `rp_core_app` | `RpCoreAppRecord`   | MISSING            | **ONLY-VIA-MODELS** |              0 |               5 |                   1 |
| `rp_core_org` | `RpCoreOrgRecord`   | MISSING            | **ONLY-VIA-MODELS** |              0 |               5 |                   1 |
| `rp_edit_org` | `RpEditOrgRecord`   | MISSING            | **USED**            |              1 |               4 |                   1 |
| `rp_palm_app` | `RpPalmAppRecord`   | MISSING            | **ONLY-VIA-MODELS** |              0 |               5 |                   1 |
| `rp_tech_org` | `RpTechOrgRecord`   | MISSING            | **ONLY-VIA-MODELS** |              0 |               5 |                   1 |
| `rp_warp_app` | `RpWarpAppRecord`   | MISSING            | **ONLY-VIA-MODELS** |              0 |               5 |                   1 |
| `rp_warp_org` | `RpWarpOrgRecord`   | MISSING            | **ONLY-VIA-MODELS** |              0 |               5 |                   1 |
| `search`      | `SearchRecord`      | PRESENT            | **UNUSED**          |              0 |               0 |                   0 |

Current inventory: 765 concrete application model classes in 22 writer database groups; 656
non-model Ruby files under app, lib and config; 1088 Ruby files under test.

### `app_setting` — `AppSettingRecord` — **USED** (`database.yml`: PRESENT)

Runtime-referenced models and one current caller example each:

- `AppPreferencePageSize` — `app/controllers/concerns/preference_class_registry.rb:75`
- `AppPreferenceDensity` — `app/controllers/concerns/preference_class_registry.rb:74`
- `AppPreferenceMotion` — `app/controllers/concerns/preference_class_registry.rb:73`
- `AppPreferenceTimeFormat` — `app/controllers/concerns/preference_class_registry.rb:72`
- `AppPreferenceDateFormat` — `app/controllers/concerns/preference_class_registry.rb:71`
- `AppPreferenceCurrency` — `app/controllers/concerns/preference_class_registry.rb:70`
- `AppPreferenceTheme` — `app/controllers/concerns/preference_class_registry.rb:69`
- `AppPreferenceRegion` — `app/controllers/concerns/preference_class_registry.rb:68`
- `AppPreferenceLanguage` — `app/controllers/concerns/preference_class_registry.rb:67`
- `AppPreferenceTimezone` — `app/controllers/concerns/preference_class_registry.rb:66`
- `AppPreferencePageSizeOption` — `app/controllers/concerns/preference_class_registry.rb:63`
- `AppPreferenceDensityOption` — `app/controllers/concerns/preference_class_registry.rb:62`
- `AppPreferenceMotionOption` — `app/controllers/concerns/preference_class_registry.rb:61`
- `AppPreferenceTimeFormatOption` — `app/controllers/concerns/preference_class_registry.rb:60`
- `AppPreferenceDateFormatOption` — `app/controllers/concerns/preference_class_registry.rb:59`
- `AppPreferenceCurrencyOption` — `app/controllers/concerns/preference_class_registry.rb:58`
- `AppPreferenceThemeOption` — `app/controllers/concerns/preference_class_registry.rb:57`
- `AppPreferenceRegionOption` — `app/controllers/concerns/preference_class_registry.rb:56`
- `AppPreferenceLanguageOption` — `app/controllers/concerns/preference_class_registry.rb:55`
- `AppPreferenceTimezoneOption` — `app/controllers/concerns/preference_class_registry.rb:54`
- `AppPreferenceCookie` — `app/controllers/concerns/preference_class_registry.rb:49`
- `AppPreference` — `app/controllers/concerns/preference_base.rb:475`
- `AppPreferenceStatus` — `app/controllers/concerns/preference_class_registry.rb:48`

Models referenced only through model source/associations and/or tests: `AppPreferenceWebPushOption`,
`AppPreferenceWebPush`, `AppPreferenceConsentReceipt`, `AppPreferenceBrowserBinding`,
`AppPreferenceAdultContentGateOption`

Models with no static runtime, model-source, association or test reference:
`AppPreferenceAdultContentGate`

### `app_signal` — `AppSignalRecord` — **USED** (`database.yml`: PRESENT)

Runtime-referenced models and one current caller example each:

- `ClientNotificationRecord` — `app/services/retention_cross_database_child_purge.rb:52`

Models referenced only through model source/associations and/or tests: `MemberNotification`

Models with no static runtime, model-source, association or test reference: None.

### `app_zenith` — `AppZenithRecord` — **USED** (`database.yml`: PRESENT)

Runtime-referenced models and one current caller example each:

- `ClientSocialAuditOutbox` — `app/jobs/social_audit_delivery_job.rb:15`
- `ClientSecretIssuance` — `app/jobs/client_secret_issuance_collection_job.rb:18`
- `ClientSecretAuditOutbox` — `app/jobs/client_secret_audit_delivery_job.rb:17`
- `ClientContactAuditOutbox` — `app/jobs/contact_audit_delivery_job.rb:14`
- `AppIdentityAuthenticationEvent` — `app/jobs/op_identity_event_delivery_job.rb:9`
- `ClientSecretCredential` — `app/jobs/client_secret_lifecycle_job.rb:47`
- `ClientPasskeyAuditOutbox` — `app/jobs/passkey_audit_delivery_job.rb:8`
- `ClientTotpCredentialStatus` — `app/operations/withdrawal_personal_data_anonymizer.rb:50`
- `ClientTotpCredential` — `app/operations/withdrawal_personal_data_anonymizer.rb:49`
- `ClientExternalIdentity` — `app/jobs/social_audit_delivery_job.rb:64`
- `ClientEnforcementRecoveryCeremony` — `app/operations/enforcement_case_end_operation.rb:146`
- `ClientStatus` — `app/operations/client_secret_passkey_reservation_issuer.rb:57`
- `Client` — `app/adapters/avatar_authority_client.rb:78`
- `ClientPasskeyStatus` — `app/operations/client_secret_passkey_reservation_issuer.rb:235`
- `ClientPasskey` — `app/jobs/retention_purge_job.rb:42`
- `ClientTelephoneStatus` — `app/operations/client_secret_passkey_reservation_issuer.rb:233`
- `ClientTelephone` — `app/jobs/retention_purge_job.rb:41`
- `ClientEmailStatus` — `app/policies/auth_method_guard.rb:6`
- `ClientEmail` — `app/jobs/retention_purge_job.rb:41`
- `Member` — `app/jobs/retention_purge_job.rb:39`
- `ClientRetentionHold` — `app/jobs/retention_purge_job.rb:36`
- `ClientPrivacyRequest` — `app/jobs/retention_purge_job.rb:35`
- `ClientProcessorErasureNotification` — `app/jobs/processor_erasure_notification_job.rb:108`
- `ClientWithdrawalFlow` — `app/jobs/retention_purge_job.rb:33`
- `AppEnforcementAppeal` — `app/jobs/enforcement_reconciliation_job.rb:19`
- `AppEnforcementCase` — `app/jobs/enforcement_expiry_job.rb:12`
- `ClientPreferencePageSize` — `app/controllers/concerns/preference_class_registry.rb:166`
- `ClientPreferenceDensity` — `app/controllers/concerns/preference_class_registry.rb:165`
- `ClientPreferenceMotion` — `app/controllers/concerns/preference_class_registry.rb:164`
- `ClientPreferenceTimeFormat` — `app/controllers/concerns/preference_class_registry.rb:163`
- `ClientPreferenceDateFormat` — `app/controllers/concerns/preference_class_registry.rb:162`
- `ClientPreferenceCurrency` — `app/controllers/concerns/preference_class_registry.rb:161`
- `ClientPreferenceTheme` — `app/controllers/concerns/preference_class_registry.rb:160`
- `ClientPreferenceRegion` — `app/controllers/concerns/preference_class_registry.rb:159`
- `ClientPreferenceLanguage` — `app/controllers/concerns/preference_class_registry.rb:158`
- `ClientPreferenceTimezone` — `app/controllers/concerns/preference_class_registry.rb:157`
- `ClientPreferencePageSizeOption` — `app/controllers/concerns/preference_class_registry.rb:154`
- `ClientPreferenceDensityOption` — `app/controllers/concerns/preference_class_registry.rb:153`
- `ClientPreferenceMotionOption` — `app/controllers/concerns/preference_class_registry.rb:152`
- `ClientPreferenceTimeFormatOption` — `app/controllers/concerns/preference_class_registry.rb:151`
- `ClientPreferenceDateFormatOption` — `app/controllers/concerns/preference_class_registry.rb:150`
- `ClientPreferenceCurrencyOption` — `app/controllers/concerns/preference_class_registry.rb:149`
- `ClientPreferenceThemeOption` — `app/controllers/concerns/preference_class_registry.rb:148`
- `ClientPreferenceRegionOption` — `app/controllers/concerns/preference_class_registry.rb:147`
- `ClientPreferenceLanguageOption` — `app/controllers/concerns/preference_class_registry.rb:146`
- `ClientPreferenceTimezoneOption` — `app/controllers/concerns/preference_class_registry.rb:145`
- `ClientPreference` — `app/controllers/concerns/preference_class_registry.rb:143`
- `PersonaMembershipKind` — `app/resolvers/avatar_permission_resolver.rb:31`
- `PersonaMembership` — `app/resolvers/avatar_permission_resolver.rb:29`
- `EnterpriseOwnership` — `app/queries/authority_owner_migration_inventory.rb:110`
- `EnterpriseLifecycle` — `app/queries/authority_owner_migration_inventory.rb:101`
- `EnterpriseAuthorityCutover` — `app/queries/authority_owner_migration_inventory.rb:118`
- `Enterprise` — `app/queries/authority_owner_migration_inventory.rb:100`
- `ClientPersonaOwnership` — `app/queries/authority_owner_migration_inventory.rb:85`
- `ClientPersonaLifecycle` — `app/queries/authority_owner_migration_inventory.rb:78`
- `ClientPersonaAuthorityCutover` — `app/queries/authority_owner_migration_inventory.rb:93`
- `ClientPersona` — `app/resolvers/avatar_permission_resolver.rb:26`
- `ClientIdentityState` — `app/queries/authority_owner_migration_inventory.rb:83`
- `ClientIdentity` — `app/services/avatar_backfill/audit_legacy_client_bindings.rb:146`
- `ClientAuthorityLock` — `app/queries/authority_owner_migration_inventory.rb:91`

Models referenced only through model source/associations and/or tests:
`ClientRegistrationCompletionMethod`, `ClientRegistrationCompletion`,
`ClientIdentifierRotationAudit`, `ClientWithdrawalCeremony`, `ClientVisibility`,
`ClientTelephoneHistory`, `ClientSecurityMode`, `ClientProcessorErasureNotificationAttempt`,
`ClientPreferenceAdultContentGateOption`, `ClientPreferenceAdultContentGate`, `ClientMembership`,
`ClientMemberSuspension`, `ClientMemberRevocation`, `ClientMemberObservation`,
`ClientMemberImpersonation`, `ClientMemberDiscovery`, `ClientMemberDeletion`, `ClientEmailHistory`,
`ClientBulletin`, `ClientBanner`, `AppEnforcementPrincipalLink`, `AppEnforcementPrincipalEffect`,
`AppEnforcementIdentifierEffect`, `AppEnforcementAuthenticationMethodEffect`, `ClientMfaStatus`,
`MemberStatus`, `ClientRetentionHoldStatus`, `ClientPrivacyRequestStatus`,
`ClientProcessorErasureNotificationStatus`, `ClientWithdrawalFlowEvent`,
`ClientWithdrawalFlowStatus`, `ClientPreferenceStatus`, `PersonaMembershipState`,
`PersonaMembershipRevokeReason`, `PersonaAssignment`, `EnterpriseViewGrant`,
`EnterpriseUnitClosure`, `EnterpriseUnit`, `EnterpriseOwnershipTransferRequest`,
`EnterpriseDelegationGrant`, `EnterpriseAdministrationGrant`, `CoreAppClientBridge`,
`ClientProfileStatus`, `ClientProfile`, `ClientPersonaViewGrant`, `ClientPersonaUsageGrant`,
`ClientPersonaOwnershipTransferRequest`, `ClientPersonaDelegationGrant`,
`ClientPersonaAdministrationGrant`, `ClientOidcIdentityBinding`, `ClientAccount`

Models with no static runtime, model-source, association or test reference:
`ClientSocialLinkSourceReceipt`, `ClientMember`, `ClientAppleNotificationEvent`

### `avatar` — `AvatarRecord` — **USED** (`database.yml`: PRESENT)

Runtime-referenced models and one current caller example each:

- `HandleStatus` — `app/services/avatar_provisioning/create.rb:88`
- `Handle` — `app/services/avatar_provisioning/create.rb:94`
- `AvatarPurgeDeferral` — `app/jobs/retention_purge_job.rb:204`
- `AvatarPersonaBinding` — `app/services/avatar_backfill/audit_legacy_client_bindings.rb:134`
- `AvatarOwnershipPeriod` — `app/operations/avatar_concrete_ownership_backfill_operation.rb:98`
- `AvatarOwnershipCutover` — `app/operations/avatar_ownership_cutover_operation.rb:55`
- `AvatarMoniker` — `app/operations/avatar_moniker_writer_operation.rb:30`
- `AvatarLifecycleState` — `app/services/avatar_provisioning/create.rb:90`
- `AvatarGroupOwnershipPeriod` —
  `app/operations/avatar_group_concrete_ownership_backfill_operation.rb:71`
- `AvatarGroupConcreteOwnershipPeriod` —
  `app/operations/avatar_group_concrete_ownership_backfill_operation.rb:92`
- `AvatarGroup` — `app/operations/avatar_group_concrete_ownership_backfill_operation.rb:64`
- `AvatarEnterprisePersonaGrant` — `app/resolvers/avatar_access_grant_resolver.rb:6`
- `AvatarEnterpriseOwnershipPeriod` —
  `app/operations/avatar_concrete_ownership_backfill_operation.rb:115`
- `AvatarCapability` — `app/services/avatar_provisioning/create.rb:89`
- `AvatarBureauOwnershipPeriod` —
  `app/operations/avatar_concrete_ownership_backfill_operation.rb:117`
- `AvatarBureauAgentGrant` — `app/resolvers/avatar_access_grant_resolver.rb:8`
- `AvatarAssignment` — `app/services/retention_cross_database_child_purge.rb:53`
- `AvatarAgentBinding` — `app/services/avatar_backfill/audit_legacy_client_bindings.rb:162`
- `Avatar` — `app/adapters/avatar_authority_client.rb:84`

Models referenced only through model source/associations and/or tests: `MemberAvatarVisibility`,
`MemberAvatarSuspension`, `MemberAvatarOversight`, `MemberAvatarImpersonation`,
`MemberAvatarExtraction`, `MemberAvatarDeletion`, `MemberAvatarAccess`, `HandleAssignmentStatus`,
`HandleAssignment`, `GroupAvatarMembership`, `AvatarTransferReservation`, `AvatarRolePermission`,
`AvatarRole`, `AvatarPermission`, `AvatarOwnershipTransfer`, `AvatarOwnershipStatus`, `AvatarMute`,
`AvatarMembershipStatus`, `AvatarMembership`, `AvatarLifecycleEvent`, `AvatarFollow`,
`AvatarEnterpriseToEnterpriseTransferDetail`, `AvatarEnterpriseToBureauTransferDetail`,
`AvatarBureauToEnterpriseTransferDetail`, `AvatarBureauToBureauTransferDetail`, `AvatarBlock`

Models with no static runtime, model-source, association or test reference: None.

### `chronicle` — `ChronicleRecord` — **USED** (`database.yml`: PRESENT)

Runtime-referenced models and one current caller example each:

- `OperatorChronicleEvent` — `app/controllers/concerns/authentication_audit_writer.rb:267`
- `ClientChronicleEvent` — `app/controllers/concerns/authentication_audit_writer.rb:257`
- `ChronicleVisibilityContext` — `app/operations/chronicle_intent_writer.rb:69`
- `ChronicleVisibility` — `app/operations/chronicle_intent_writer.rb:61`
- `ChronicleRetentionPolicy` — `app/jobs/client_secret_audit_delivery_job.rb:80`
- `ChronicleOutboxEntry` — `app/controllers/concerns/authentication_audit_writer.rb:143`
- `Chronicle` — `app/jobs/client_secret_audit_delivery_job.rb:58`
- `AccountAccessEvent` — `app/jobs/enforcement_reconciliation_job.rb:93`
- `OperatorChronicleLevel` — `app/controllers/concerns/authentication_audit_writer.rb:328`
- `OperatorChronicle` — `app/controllers/concerns/authentication_audit_writer.rb:265`
- `ClientChronicleLevel` — `app/controllers/concerns/authentication_audit_writer.rb:323`
- `ClientChronicle` — `app/controllers/concerns/authentication_audit_writer.rb:255`
- `OrgPreferenceChronicle` — `app/controllers/concerns/authentication_audit_writer.rb:297`
- `ComPreferenceChronicle` — `app/controllers/concerns/authentication_audit_writer.rb:286`
- `AppPreferenceChronicle` — `app/controllers/concerns/authentication_audit_writer.rb:275`
- `OrgPreferenceChronicleEvent` — `app/controllers/concerns/authentication_audit_writer.rb:299`
- `ComPreferenceChronicleEvent` — `app/controllers/concerns/authentication_audit_writer.rb:288`
- `AppPreferenceChronicleEvent` — `app/controllers/concerns/authentication_audit_writer.rb:277`
- `OrgPreferenceChronicleLevel` — `app/controllers/concerns/preference_class_registry.rb:116`
- `ComPreferenceChronicleLevel` — `app/controllers/concerns/preference_class_registry.rb:84`
- `AppPreferenceChronicleLevel` — `app/controllers/concerns/preference_class_registry.rb:52`

Models referenced only through model source/associations and/or tests: `EnforcementEvent`

Models with no static runtime, model-source, association or test reference: None.

### `com_setting` — `ComSettingRecord` — **USED** (`database.yml`: PRESENT)

Runtime-referenced models and one current caller example each:

- `ComPreferenceWebPushOption` — `app/controllers/concerns/preference_base.rb:106`
- `ComPreferenceWebPush` — `app/controllers/concerns/preference_base.rb:108`
- `ComPreferenceConsentReceipt` — `app/controllers/concerns/preference_browser_binding.rb:53`
- `ComPreferenceBrowserBinding` — `app/controllers/concerns/preference_browser_binding.rb:50`
- `ComPreferencePageSize` — `app/controllers/concerns/preference_class_registry.rb:107`
- `ComPreferenceDensity` — `app/controllers/concerns/preference_class_registry.rb:106`
- `ComPreferenceMotion` — `app/controllers/concerns/preference_class_registry.rb:105`
- `ComPreferenceTimeFormat` — `app/controllers/concerns/preference_class_registry.rb:104`
- `ComPreferenceDateFormat` — `app/controllers/concerns/preference_class_registry.rb:103`
- `ComPreferenceCurrency` — `app/controllers/concerns/preference_class_registry.rb:102`
- `ComPreferenceTheme` — `app/controllers/concerns/preference_class_registry.rb:101`
- `ComPreferenceRegion` — `app/controllers/concerns/preference_class_registry.rb:100`
- `ComPreferenceLanguage` — `app/controllers/concerns/preference_class_registry.rb:99`
- `ComPreferenceTimezone` — `app/controllers/concerns/preference_class_registry.rb:98`
- `ComPreferencePageSizeOption` — `app/controllers/concerns/preference_class_registry.rb:95`
- `ComPreferenceDensityOption` — `app/controllers/concerns/preference_class_registry.rb:94`
- `ComPreferenceMotionOption` — `app/controllers/concerns/preference_class_registry.rb:93`
- `ComPreferenceTimeFormatOption` — `app/controllers/concerns/preference_class_registry.rb:92`
- `ComPreferenceDateFormatOption` — `app/controllers/concerns/preference_class_registry.rb:91`
- `ComPreferenceCurrencyOption` — `app/controllers/concerns/preference_class_registry.rb:90`
- `ComPreferenceThemeOption` — `app/controllers/concerns/preference_class_registry.rb:89`
- `ComPreferenceRegionOption` — `app/controllers/concerns/preference_class_registry.rb:88`
- `ComPreferenceLanguageOption` — `app/controllers/concerns/preference_class_registry.rb:87`
- `ComPreferenceTimezoneOption` — `app/controllers/concerns/preference_class_registry.rb:86`
- `ComPreferenceCookie` — `app/controllers/concerns/preference_browser_binding.rb:66`
- `ComPreference` — `app/controllers/concerns/preference_base.rb:469`
- `ComPreferenceStatus` — `app/controllers/concerns/preference_class_registry.rb:80`

Models referenced only through model source/associations and/or tests:
`ComPreferenceAdultContentGateOption`, `ComPreferenceAdultContentGate`

Models with no static runtime, model-source, association or test reference: None.

### `occurrence` — `OccurrenceRecord` — **USED** (`database.yml`: PRESENT)

Runtime-referenced models and one current caller example each:

- `JwtAnomalyEvent` — `app/subscribers/jwt_anomaly_subscriber.rb:34`
- `TelephoneOccurrence` — `app/jobs/retention_purge_job.rb:47`
- `JwtOccurrence` — `app/jobs/retention_purge_job.rb:47`
- `EmailOccurrence` — `app/jobs/retention_purge_job.rb:47`
- `IpOccurrence` — `app/jobs/retention_purge_job.rb:47`
- `DomainOccurrence` — `app/jobs/retention_purge_job.rb:47`
- `ZipOccurrence` — `app/jobs/retention_purge_job.rb:46`
- `OperatorOccurrenceStatus` — `app/services/sign_risk_emitter.rb:76`
- `OperatorOccurrence` — `app/jobs/retention_purge_job.rb:46`
- `VisitorOccurrence` — `app/jobs/retention_purge_job.rb:46`
- `ClientOccurrenceStatus` — `app/services/sign_risk_emitter.rb:60`
- `ClientOccurrence` — `app/jobs/retention_purge_job.rb:46`
- `AreaOccurrence` — `app/jobs/retention_purge_job.rb:46`

Models referenced only through model source/associations and/or tests: `TelephoneZipOccurrence`,
`TelephoneClientOccurrence`, `OperatorZipOccurrence`, `OperatorTelephoneOccurrence`,
`OperatorClientOccurrence`, `IpZipOccurrence`, `IpVisitorOccurrence`, `IpTelephoneOccurrence`,
`IpOperatorOccurrence`, `IpClientOccurrence`, `EmailZipOccurrence`, `EmailVisitorOccurrence`,
`EmailTelephoneOccurrence`, `EmailOperatorOccurrence`, `EmailIpOccurrence`, `EmailClientOccurrence`,
`DomainZipOccurrence`, `DomainTelephoneOccurrence`, `DomainOperatorOccurrence`,
`DomainIpOccurrence`, `DomainEmailOccurrence`, `DomainClientOccurrence`, `ClientZipOccurrence`,
`AreaZipOccurrence`, `AreaVisitorOccurrence`, `AreaTelephoneOccurrence`, `AreaOperatorOccurrence`,
`AreaIpOccurrence`, `AreaEmailOccurrence`, `AreaDomainOccurrence`, `AreaClientOccurrence`,
`TelephoneOccurrenceStatus`, `JwtOccurrenceStatus`, `EmailOccurrenceStatus`, `IpOccurrenceStatus`,
`DomainOccurrenceStatus`, `ZipOccurrenceStatus`, `VisitorOccurrenceStatus`, `AreaOccurrenceStatus`

Models with no static runtime, model-source, association or test reference: None.

### `op_base_app` — `OpBaseAppRecord` — **USED** (`database.yml`: PRESENT)

Runtime-referenced models and one current caller example each:

- `SecurityOneTimeReveal` — `app/jobs/security_one_time_reveal_purge_job.rb:27`
- `SecurityConsumedJti` — `app/jobs/security_consumed_jti_purge_job.rb:27`
- `OpAppInboundEventReceipt` — `app/operations/op_identity_event_invalidator.rb:13`
- `OpAppGrant` — `app/controllers/concerns/browser_rp_authentication.rb:354`
- `OpAppAuthorityStopRootTarget` — `app/operations/op_authority_stop_committer.rb:29`
- `OpAppAuthorityStopGrantTarget` — `app/operations/op_authority_stop_committer.rb:30`
- `OpAppAuthorityStopEpochCutoff` — `app/operations/op_authority_stop_committer.rb:31`
- `OpAppAuthorityStop` — `app/operations/op_authority_stop_committer.rb:28`
- `IdentityTotpCeremonyCandidate` —
  `app/operations/identity_step_up_ceremony_transaction_purger.rb:12`
- `IdentityPasskeyCeremonyCandidate` —
  `app/operations/identity_step_up_ceremony_transaction_purger.rb:12`
- `ClientTotpCeremonyTransaction` —
  `app/operations/identity_step_up_ceremony_transaction_purger.rb:12`
- `ClientTelephoneCeremonyTransaction` —
  `app/operations/identity_telephone_ceremony_transaction_purger.rb:6`
- `ClientStepUpCommit` — `app/controllers/concerns/authentication_session_revoker.rb:50`
- `ClientStepUpCeremonyTransaction` — `app/operations/auth_admission_binding_purger.rb:11`
- `ClientStepUpAuditOutboxDeliveryState` — `app/values/step_up_audit_outbox_sources_registry.rb:8`
- `ClientStepUpAuditOutboxAttempt` — `app/values/step_up_audit_outbox_sources_registry.rb:14`
- `ClientStepUpAuditOutbox` — `app/values/step_up_audit_outbox_sources_registry.rb:12`
- `ClientSocialCeremonyTransaction` —
  `app/operations/identity_social_ceremony_transaction_purger.rb:6`
- `ClientSensitiveAdmissionAuditOutbox` — `app/values/step_up_audit_outbox_sources_registry.rb:7`
- `ClientSensitiveAdmissionAuditAttempt` — `app/values/step_up_audit_outbox_sources_registry.rb:7`
- `ClientSecretSignInReceipt` — `app/jobs/client_secret_lifecycle_job.rb:71`
- `ClientSecretCredentialCeremonyTransaction` —
  `app/operations/identity_secret_credential_ceremony_transaction_purger.rb:6`
- `ClientPasskeyCeremonyTransaction` —
  `app/operations/identity_passkey_ceremony_transaction_purger.rb:6`
- `ClientOidcAuthorizationTransaction` — `app/jobs/retention_purge_job.rb:374`
- `ClientEmailCeremonyTransaction` —
  `app/operations/identity_email_ceremony_transaction_purger.rb:6`
- `ClientDeviceSession` — `app/controllers/concerns/authentication_logout_current_session.rb:194`
- `ClientAuthCeremonySession` — `app/operations/client_secret_claim_finalizer.rb:71`
- `ClientAuthAdmissionBinding` — `app/operations/auth_admission_binding_purger.rb:9`
- `ClientStepUpSession` — `app/jobs/retention_purge_job.rb:45`
- `ClientVerification` — `app/controllers/concerns/verification_base.rb:458`
- `ClientToken` — `app/controllers/concerns/browser_rp_authentication.rb:338`
- `ClientSignUpFlow` — `app/jobs/client_secret_lifecycle_job.rb:99`
- `ClientSignInFlow` — `app/jobs/client_secret_lifecycle_job.rb:70`
- `ClientSessionLimitResolutionTransaction` — `app/jobs/retention_purge_job.rb:31`
- `OpAppAuthorityStopParticipant` — `app/jobs/op_outbox_dispatch_job.rb:17`
- `ClientDpopProofState` — `app/jobs/dpop_proof_state_purge_job.rb:19`

Models referenced only through model source/associations and/or tests: `TurnstileReplay`,
`OpAppGrantLogoutHint`, `OpAppConsumedJti`, `OpAppAuthorityStopScope`,
`OpAppAuthorityStopParticipantStatus`, `OpAppAuthorityStopCause`, `LogoutTransaction`,
`IdentitySocialCeremonyCandidate`, `ClientStepUpContextTransition`, `ClientStepUpContextState`,
`ClientStepUpContext`, `ClientSignUpFlowCleanupStatus`, `ClientSessionLimitResolutionState`,
`ClientSensitiveAdmission`, `ClientVisaSensitiveAdmission`,
`ClientOidcAuthorizationTransactionStatus`, `ClientAuthCeremonySessionStatus`,
`ClientAuthAdmissionBindingStatus`, `ClientTokenKind`, `ClientTokenStatus`, `ClientOidcConnection`,
`ClientTokenDbscStatus`, `ClientTokenBindingMethod`, `ClientSignUpFlowStatus`,
`ClientSignInFlowState`

Models with no static runtime, model-source, association or test reference:
`IdentitySecretCredentialCeremonyCandidate`, `ClientVisaSocialLinkAdmission`,
`ClientOauthCallbackState`, `ClientEmergencySignInOperation`

### `op_base_org` — `OpBaseOrgRecord` — **USED** (`database.yml`: PRESENT)

Runtime-referenced models and one current caller example each:

- `OperatorTelephoneCeremonyTransaction` —
  `app/operations/identity_telephone_ceremony_transaction_purger.rb:7`
- `OperatorStepUpCommit` — `app/controllers/concerns/authentication_session_revoker.rb:51`
- `OperatorStepUpCeremonyTransaction` — `app/operations/auth_admission_binding_purger.rb:12`
- `OperatorStepUpAuditOutboxDeliveryState` —
  `app/values/step_up_audit_outbox_sources_registry.rb:10`
- `OperatorStepUpAuditOutboxAttempt` — `app/values/step_up_audit_outbox_sources_registry.rb:21`
- `OperatorStepUpAuditOutbox` — `app/values/step_up_audit_outbox_sources_registry.rb:19`
- `OperatorSensitiveAdmissionAuditOutbox` — `app/values/step_up_audit_outbox_sources_registry.rb:9`
- `OperatorSensitiveAdmissionAuditAttempt` — `app/values/step_up_audit_outbox_sources_registry.rb:9`
- `OperatorSecretCredentialCeremonyTransaction` —
  `app/operations/identity_secret_credential_ceremony_transaction_purger.rb:7`
- `OperatorPasskeyCeremonyTransaction` —
  `app/operations/identity_passkey_ceremony_transaction_purger.rb:7`
- `OperatorPasskeyCeremonyCandidate` —
  `app/operations/identity_step_up_ceremony_transaction_purger.rb:16`
- `OperatorOidcAuthorizationTransaction` — `app/operations/auth_admission_binding_purger.rb:10`
- `OperatorEmailCeremonyTransaction` —
  `app/operations/identity_email_ceremony_transaction_purger.rb:7`
- `OperatorDeviceSession` — `app/controllers/concerns/authentication_logout_current_session.rb:195`
- `OperatorAuthCeremonySession` —
  `app/operations/identity_step_up_ceremony_transaction_purger.rb:15`
- `OperatorAuthAdmissionBinding` — `app/operations/auth_admission_binding_purger.rb:10`
- `OpOrgInboundEventReceipt` — `app/operations/op_identity_event_invalidator.rb:14`
- `OpOrgGrant` — `app/controllers/concerns/browser_rp_authentication.rb:353`
- `OpOrgAuthorityStopRootTarget` — `app/operations/op_authority_stop_committer.rb:42`
- `OpOrgAuthorityStopGrantTarget` — `app/operations/op_authority_stop_committer.rb:43`
- `OpOrgAuthorityStopEpochCutoff` — `app/operations/op_authority_stop_committer.rb:44`
- `OpOrgAuthorityStop` — `app/operations/op_authority_stop_committer.rb:41`
- `OperatorStepUpSession` — `app/jobs/retention_purge_job.rb:45`
- `OperatorVerification` — `app/controllers/concerns/verification_base.rb:458`
- `OperatorToken` — `app/controllers/concerns/browser_rp_authentication.rb:337`
- `OperatorSignUpFlow` — `app/jobs/retention_purge_job.rb:37`
- `OperatorSignInFlow` — `app/jobs/retention_purge_job.rb:32`
- `OperatorSessionLimitResolutionTransaction` — `app/jobs/retention_purge_job.rb:31`
- `OpOrgAuthorityStopParticipant` — `app/jobs/op_outbox_dispatch_job.rb:18`
- `OperatorDpopProofState` — `app/jobs/dpop_proof_state_purge_job.rb:20`

Models referenced only through model source/associations and/or tests: `OrganizationInvitation`,
`OperatorStepUpContextTransition`, `OperatorStepUpContextState`, `OperatorStepUpContext`,
`OperatorSessionLimitResolutionState`, `OperatorSensitiveAdmission`,
`OperatorOidcAuthorizationTransactionStatus`, `OperatorAuthCeremonySessionStatus`,
`OperatorAuthAdmissionBindingStatus`, `OpOrgGrantLogoutHint`, `OpOrgConsumedJti`,
`OpOrgAuthorityStopScope`, `OpOrgAuthorityStopParticipantStatus`, `OpOrgAuthorityStopCause`,
`OperatorTokenKind`, `OperatorTokenStatus`, `OperatorOidcConnection`, `OperatorTokenDbscStatus`,
`OperatorTokenBindingMethod`, `OperatorSignUpFlowStatus`, `OperatorSignInFlowState`

Models with no static runtime, model-source, association or test reference:
`OperatorVisaSensitiveAdmission`, `OperatorOauthCallbackState`

### `org_setting` — `OrgSettingRecord` — **USED** (`database.yml`: PRESENT)

Runtime-referenced models and one current caller example each:

- `OrgPreferencePageSize` — `app/controllers/concerns/preference_class_registry.rb:139`
- `OrgPreferenceDensity` — `app/controllers/concerns/preference_class_registry.rb:138`
- `OrgPreferenceMotion` — `app/controllers/concerns/preference_class_registry.rb:137`
- `OrgPreferenceTimeFormat` — `app/controllers/concerns/preference_class_registry.rb:136`
- `OrgPreferenceDateFormat` — `app/controllers/concerns/preference_class_registry.rb:135`
- `OrgPreferenceCurrency` — `app/controllers/concerns/preference_class_registry.rb:134`
- `OrgPreferenceTheme` — `app/controllers/concerns/preference_class_registry.rb:133`
- `OrgPreferenceRegion` — `app/controllers/concerns/preference_class_registry.rb:132`
- `OrgPreferenceLanguage` — `app/controllers/concerns/preference_class_registry.rb:131`
- `OrgPreferenceTimezone` — `app/controllers/concerns/preference_class_registry.rb:130`
- `OrgPreferencePageSizeOption` — `app/controllers/concerns/preference_class_registry.rb:127`
- `OrgPreferenceDensityOption` — `app/controllers/concerns/preference_class_registry.rb:126`
- `OrgPreferenceMotionOption` — `app/controllers/concerns/preference_class_registry.rb:125`
- `OrgPreferenceTimeFormatOption` — `app/controllers/concerns/preference_class_registry.rb:124`
- `OrgPreferenceDateFormatOption` — `app/controllers/concerns/preference_class_registry.rb:123`
- `OrgPreferenceCurrencyOption` — `app/controllers/concerns/preference_class_registry.rb:122`
- `OrgPreferenceThemeOption` — `app/controllers/concerns/preference_class_registry.rb:121`
- `OrgPreferenceRegionOption` — `app/controllers/concerns/preference_class_registry.rb:120`
- `OrgPreferenceLanguageOption` — `app/controllers/concerns/preference_class_registry.rb:119`
- `OrgPreferenceTimezoneOption` — `app/controllers/concerns/preference_class_registry.rb:118`
- `OrgPreferenceCookie` — `app/controllers/concerns/preference_class_registry.rb:113`
- `OrgPreference` — `app/controllers/concerns/preference_base.rb:475`
- `OrgPreferenceStatus` — `app/controllers/concerns/preference_class_registry.rb:112`

Models referenced only through model source/associations and/or tests: `OrgPreferenceWebPushOption`,
`OrgPreferenceWebPush`, `OrgPreferenceConsentReceipt`, `OrgPreferenceBrowserBinding`,
`OrgPreferenceAdultContentGateOption`, `OrgPreferenceAdultContentGate`

Models with no static runtime, model-source, association or test reference: None.

### `org_signal` — `OrgSignalRecord` — **USED** (`database.yml`: PRESENT)

Runtime-referenced models and one current caller example each:

- `OperatorNotificationRecord` — `app/services/retention_cross_database_child_purge.rb:57`

Models referenced only through model source/associations and/or tests: `OperatorNotification`

Models with no static runtime, model-source, association or test reference: None.

### `org_zenith` — `OrgZenithRecord` — **USED** (`database.yml`: PRESENT)

Runtime-referenced models and one current caller example each:

- `OrgIdentityAuthenticationEvent` — `app/jobs/op_identity_event_delivery_job.rb:9`
- `OperatorPasskeyAuditOutbox` — `app/jobs/passkey_audit_delivery_job.rb:9`
- `OperatorTelephoneHistory` — `app/jobs/retention_purge_job.rb:424`
- `OperatorTelephoneStatus` — `app/queries/authentication_credential_inventory.rb:188`
- `OperatorTelephone` — `app/operations/operator_telephone_public_id_backfill_operation.rb:8`
- `OperatorPasskeyStatus` — `app/queries/authentication_credential_inventory.rb:210`
- `OperatorPasskey` — `app/operations/passkey_registration_operation.rb:12`
- `OperatorEmailHistory` — `app/jobs/retention_purge_job.rb:423`
- `OperatorEmailStatus` — `app/queries/authentication_credential_inventory.rb:163`
- `OperatorEmail` — `app/operations/email_identifier_purger.rb:12`
- `OperatorCapabilityGrant` — `app/policies/enforcement_case_policy.rb:25`
- `OperatorStatus` — `app/resolvers/avatar_permission_resolver.rb:35`
- `Operator` — `app/controllers/concerns/browser_rp_authentication.rb:329`
- `OperatorSecretCredential` — `app/jobs/retention_purge_job.rb:38`
- `OrgEnforcementAppeal` — `app/jobs/enforcement_reconciliation_job.rb:19`
- `OrgEnforcementCase` — `app/jobs/enforcement_expiry_job.rb:12`
- `OperatorPreferencePageSize` — `app/controllers/concerns/preference_class_registry.rb:193`
- `OperatorPreferenceDensity` — `app/controllers/concerns/preference_class_registry.rb:192`
- `OperatorPreferenceMotion` — `app/controllers/concerns/preference_class_registry.rb:191`
- `OperatorPreferenceTimeFormat` — `app/controllers/concerns/preference_class_registry.rb:190`
- `OperatorPreferenceDateFormat` — `app/controllers/concerns/preference_class_registry.rb:189`
- `OperatorPreferenceCurrency` — `app/controllers/concerns/preference_class_registry.rb:188`
- `OperatorPreferenceTheme` — `app/controllers/concerns/preference_class_registry.rb:187`
- `OperatorPreferenceRegion` — `app/controllers/concerns/preference_class_registry.rb:186`
- `OperatorPreferenceLanguage` — `app/controllers/concerns/preference_class_registry.rb:185`
- `OperatorPreferenceTimezone` — `app/controllers/concerns/preference_class_registry.rb:184`
- `OperatorPreferencePageSizeOption` — `app/controllers/concerns/preference_class_registry.rb:181`
- `OperatorPreferenceDensityOption` — `app/controllers/concerns/preference_class_registry.rb:180`
- `OperatorPreferenceMotionOption` — `app/controllers/concerns/preference_class_registry.rb:179`
- `OperatorPreferenceTimeFormatOption` — `app/controllers/concerns/preference_class_registry.rb:178`
- `OperatorPreferenceDateFormatOption` — `app/controllers/concerns/preference_class_registry.rb:177`
- `OperatorPreferenceCurrencyOption` — `app/controllers/concerns/preference_class_registry.rb:176`
- `OperatorPreferenceThemeOption` — `app/controllers/concerns/preference_class_registry.rb:175`
- `OperatorPreferenceRegionOption` — `app/controllers/concerns/preference_class_registry.rb:174`
- `OperatorPreferenceLanguageOption` — `app/controllers/concerns/preference_class_registry.rb:173`
- `OperatorPreferenceTimezoneOption` — `app/controllers/concerns/preference_class_registry.rb:172`
- `OperatorPreference` — `app/controllers/concerns/preference_class_registry.rb:170`
- `OperatorIdentityState` — `app/queries/authority_owner_migration_inventory.rb:131`
- `OperatorIdentity` — `app/queries/authority_owner_migration_inventory.rb:130`
- `OperatorEntraIdentity` — `app/services/retention_cross_database_child_purge.rb:63`
- `OperatorAuthorityLock` — `app/queries/authority_owner_migration_inventory.rb:139`
- `BureauOwnership` — `app/queries/authority_owner_migration_inventory.rb:158`
- `BureauLifecycle` — `app/queries/authority_owner_migration_inventory.rb:149`
- `BureauAuthorityCutover` — `app/queries/authority_owner_migration_inventory.rb:166`
- `Bureau` — `app/queries/authority_owner_migration_inventory.rb:148`
- `AgentOwnership` — `app/queries/authority_owner_migration_inventory.rb:133`
- `AgentMembershipKind` — `app/resolvers/avatar_permission_resolver.rb:42`
- `AgentMembership` — `app/resolvers/avatar_permission_resolver.rb:40`
- `AgentLifecycle` — `app/queries/authority_owner_migration_inventory.rb:126`
- `AgentAuthorityCutover` — `app/queries/authority_owner_migration_inventory.rb:141`
- `Agent` — `app/resolvers/avatar_permission_resolver.rb:37`
- `OperatorWorkspaceAccount` — `app/jobs/retention_purge_job.rb:39`

Models referenced only through model source/associations and/or tests: `OrganizationStatus`,
`OrgIamOperationOutcome`, `OrgEnforcementPrincipalLink`, `OrgEnforcementPrincipalEffect`,
`OrgEnforcementIdentifierEffect`, `OrgEnforcementAuthenticationMethodEffect`, `OperatorVisibility`,
`OperatorSecurityMode`, `OperatorPreferenceAdultContentGateOption`,
`OperatorPreferenceAdultContentGate`, `OperatorOrganization`, `OperatorLifecycleRequest`,
`OperatorBulletin`, `OperatorBanner`, `DivisionStatus`, `Division`, `DepartmentStatus`,
`Department`, `OperatorMfaStatus`, `OperatorWorkspaceAccountStatus`,
`OperatorSecretCredentialStatus`, `OperatorSecretCredentialKind`, `OperatorPreferenceStatus`,
`OrganizationEntraConnectionState`, `OrganizationEntraConnection`,
`OperatorWorkspaceAccountMembership`, `OperatorOidcIdentityBinding`, `OperatorEntraIdentityState`,
`OperatorAccount`, `CoreOrgOperatorBridge`, `BureauViewGrant`, `BureauUnitClosure`, `BureauUnit`,
`BureauOwnershipTransferRequest`, `BureauDelegationGrant`, `BureauAdministrationGrant`,
`AgentViewGrant`, `AgentUsageGrant`, `AgentOwnershipTransferRequest`, `AgentMembershipState`,
`AgentMembershipRevokeReason`, `AgentDelegationGrant`, `AgentAssignment`, `AgentAdministrationGrant`

Models with no static runtime, model-source, association or test reference:
`OperatorIdentifierRotationAudit`

### `publishing` — `PublishingRecord` — **USED** (`database.yml`: PRESENT)

Runtime-referenced models and one current caller example each:

- `Publishing::News::Org::Entry` —
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:60`
- `Publishing::News::Com::Entry` —
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:59`
- `Publishing::News::App::Entry` —
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:58`
- `Publishing::Info::Org::Entry` —
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:57`
- `Publishing::Info::Com::Entry` —
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:56`
- `Publishing::Info::App::Entry` —
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:55`
- `Publishing::Help::Org::Entry` —
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:54`
- `Publishing::Help::Com::Entry` —
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:53`
- `Publishing::Help::App::Entry` —
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:52`
- `Publishing::Docs::Org::Entry` —
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:51`
- `Publishing::Docs::Com::Entry` —
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:50`
- `Publishing::Docs::App::Entry` —
  `app/controllers/concerns/publishing_authority_api_endpoint.rb:49`

Models referenced only through model source/associations and/or tests:
`Publishing::Info::Org::EntrySlug`, `Publishing::Info::Com::EntrySlug`,
`Publishing::Info::App::EntrySlug`, `Publishing::Docs::App::Publication`,
`Publishing::Docs::App::EntrySlug`, `Publishing::MediaFile`,
`Publishing::Help::Org::VersionMediaUsage`,
`Publishing::Help::Org::VersionMultipleTaxonomyAssignment`,
`Publishing::Help::Org::VersionSingleTaxonomyAssignment`,
`Publishing::Help::Org::RevisionMediaUsage`,
`Publishing::Help::Org::RevisionMultipleTaxonomyAssignment`,
`Publishing::Help::Org::RevisionSingleTaxonomyAssignment`, `Publishing::Help::Org::TaxonomyTerm`,
`Publishing::Help::Org::Vocabulary`, `Publishing::Help::Org::EntryVersion`,
`Publishing::Help::Org::EntryRevision`, `Publishing::Help::Com::VersionMediaUsage`,
`Publishing::Help::Com::VersionMultipleTaxonomyAssignment`,
`Publishing::Help::Com::VersionSingleTaxonomyAssignment`,
`Publishing::Help::Com::RevisionMediaUsage`,
`Publishing::Help::Com::RevisionMultipleTaxonomyAssignment`,
`Publishing::Help::Com::RevisionSingleTaxonomyAssignment`, `Publishing::Help::Com::TaxonomyTerm`,
`Publishing::Help::Com::Vocabulary`, `Publishing::Help::Com::EntryVersion`,
`Publishing::Help::Com::EntryRevision`, `Publishing::Help::App::VersionMediaUsage`,
`Publishing::Help::App::VersionMultipleTaxonomyAssignment`,
`Publishing::Help::App::VersionSingleTaxonomyAssignment`,
`Publishing::Help::App::RevisionMediaUsage`,
`Publishing::Help::App::RevisionMultipleTaxonomyAssignment`,
`Publishing::Help::App::RevisionSingleTaxonomyAssignment`, `Publishing::Help::App::TaxonomyTerm`,
`Publishing::Help::App::Vocabulary`, `Publishing::Help::App::EntryVersion`,
`Publishing::Help::App::EntryRevision`, `Publishing::News::Org::VersionMediaUsage`,
`Publishing::News::Org::VersionMultipleTaxonomyAssignment`,
`Publishing::News::Org::VersionSingleTaxonomyAssignment`,
`Publishing::News::Org::RevisionMediaUsage`,
`Publishing::News::Org::RevisionMultipleTaxonomyAssignment`,
`Publishing::News::Org::RevisionSingleTaxonomyAssignment`, `Publishing::News::Org::TaxonomyTerm`,
`Publishing::News::Org::Vocabulary`, `Publishing::News::Org::EntryVersion`,
`Publishing::News::Org::EntryRevision`, `Publishing::News::Com::VersionMediaUsage`,
`Publishing::News::Com::VersionMultipleTaxonomyAssignment`,
`Publishing::News::Com::VersionSingleTaxonomyAssignment`,
`Publishing::News::Com::RevisionMediaUsage`,
`Publishing::News::Com::RevisionMultipleTaxonomyAssignment`,
`Publishing::News::Com::RevisionSingleTaxonomyAssignment`, `Publishing::News::Com::TaxonomyTerm`,
`Publishing::News::Com::Vocabulary`, `Publishing::News::Com::EntryVersion`,
`Publishing::News::Com::EntryRevision`, `Publishing::News::App::VersionMediaUsage`,
`Publishing::News::App::VersionMultipleTaxonomyAssignment`,
`Publishing::News::App::VersionSingleTaxonomyAssignment`,
`Publishing::News::App::RevisionMediaUsage`,
`Publishing::News::App::RevisionMultipleTaxonomyAssignment`,
`Publishing::News::App::RevisionSingleTaxonomyAssignment`, `Publishing::News::App::TaxonomyTerm`,
`Publishing::News::App::Vocabulary`, `Publishing::News::App::EntryVersion`,
`Publishing::News::App::EntryRevision`, `Publishing::Docs::Org::VersionMediaUsage`,
`Publishing::Docs::Org::VersionMultipleTaxonomyAssignment`,
`Publishing::Docs::Org::VersionSingleTaxonomyAssignment`,
`Publishing::Docs::Org::RevisionMediaUsage`,
`Publishing::Docs::Org::RevisionMultipleTaxonomyAssignment`,
`Publishing::Docs::Org::RevisionSingleTaxonomyAssignment`, `Publishing::Docs::Org::TaxonomyTerm`,
`Publishing::Docs::Org::Vocabulary`, `Publishing::Docs::Org::EntryVersion`,
`Publishing::Docs::Org::EntryRevision`, `Publishing::Docs::Com::VersionMediaUsage`,
`Publishing::Docs::Com::VersionMultipleTaxonomyAssignment`,
`Publishing::Docs::Com::VersionSingleTaxonomyAssignment`,
`Publishing::Docs::Com::RevisionMediaUsage`,
`Publishing::Docs::Com::RevisionMultipleTaxonomyAssignment`,
`Publishing::Docs::Com::RevisionSingleTaxonomyAssignment`, `Publishing::Docs::Com::TaxonomyTerm`,
`Publishing::Docs::Com::Vocabulary`, `Publishing::Docs::Com::EntryVersion`,
`Publishing::Docs::Com::EntryRevision`, `Publishing::Docs::App::VersionMediaUsage`,
`Publishing::Docs::App::VersionMultipleTaxonomyAssignment`,
`Publishing::Docs::App::VersionSingleTaxonomyAssignment`,
`Publishing::Docs::App::RevisionMediaUsage`,
`Publishing::Docs::App::RevisionMultipleTaxonomyAssignment`,
`Publishing::Docs::App::RevisionSingleTaxonomyAssignment`, `Publishing::Docs::App::TaxonomyTerm`,
`Publishing::Docs::App::Vocabulary`, `Publishing::Docs::App::EntryVersion`,
`Publishing::Docs::App::EntryRevision`, `Publishing::Info::Org::VersionMediaUsage`,
`Publishing::Info::Org::VersionMultipleTaxonomyAssignment`,
`Publishing::Info::Org::VersionSingleTaxonomyAssignment`,
`Publishing::Info::Org::RevisionMediaUsage`,
`Publishing::Info::Org::RevisionMultipleTaxonomyAssignment`,
`Publishing::Info::Org::RevisionSingleTaxonomyAssignment`, `Publishing::Info::Org::TaxonomyTerm`,
`Publishing::Info::Org::Vocabulary`, `Publishing::Info::Org::EntryVersion`,
`Publishing::Info::Org::EntryRevision`, `Publishing::Info::Com::VersionMediaUsage`,
`Publishing::Info::Com::VersionMultipleTaxonomyAssignment`,
`Publishing::Info::Com::VersionSingleTaxonomyAssignment`,
`Publishing::Info::Com::RevisionMediaUsage`,
`Publishing::Info::Com::RevisionMultipleTaxonomyAssignment`,
`Publishing::Info::Com::RevisionSingleTaxonomyAssignment`, `Publishing::Info::Com::TaxonomyTerm`,
`Publishing::Info::Com::Vocabulary`, `Publishing::Info::Com::EntryVersion`,
`Publishing::Info::Com::EntryRevision`, `Publishing::Info::App::VersionMediaUsage`,
`Publishing::Info::App::VersionMultipleTaxonomyAssignment`,
`Publishing::Info::App::VersionSingleTaxonomyAssignment`,
`Publishing::Info::App::RevisionMediaUsage`,
`Publishing::Info::App::RevisionMultipleTaxonomyAssignment`,
`Publishing::Info::App::RevisionSingleTaxonomyAssignment`, `Publishing::Info::App::TaxonomyTerm`,
`Publishing::Info::App::Vocabulary`, `Publishing::Info::App::EntryVersion`,
`Publishing::Info::App::EntryRevision`

Models with no static runtime, model-source, association or test reference:
`Publishing::News::Org::Publication`, `Publishing::News::Org::EntrySlug`,
`Publishing::News::Com::Publication`, `Publishing::News::Com::EntrySlug`,
`Publishing::News::App::Publication`, `Publishing::News::App::EntrySlug`,
`Publishing::Info::Org::Publication`, `Publishing::Info::Com::Publication`,
`Publishing::Info::App::Publication`, `Publishing::Help::Org::Publication`,
`Publishing::Help::Org::EntrySlug`, `Publishing::Help::Com::Publication`,
`Publishing::Help::Com::EntrySlug`, `Publishing::Help::App::Publication`,
`Publishing::Help::App::EntrySlug`, `Publishing::Docs::Org::Publication`,
`Publishing::Docs::Org::EntrySlug`, `Publishing::Docs::Com::Publication`,
`Publishing::Docs::Com::EntrySlug`

### `rp_base_app` — `RpBaseAppRecord` — **USED** (`database.yml`: MISSING)

Runtime-referenced models and one current caller example each:

- `RpStepUpAuditOutboxDeliveryState` — `app/values/step_up_audit_outbox_sources_registry.rb:29`
- `RpStepUpAuditOutboxAttempt` — `app/values/step_up_audit_outbox_sources_registry.rb:28`
- `RpStepUpAuditOutbox` — `app/values/step_up_audit_outbox_sources_registry.rb:26`

Models referenced only through model source/associations and/or tests: `RpStepUpStateTransition`,
`RpStepUpStateStatus`, `RpStepUpState`, `RpBaseAppSessionSelection`, `RpBaseAppSession`,
`RpBaseAppPrincipal`, `RpBaseAppOpSessionBinding`, `RpBaseAppIdentityBinding`,
`RpBaseAppEventReceipt`

Models with no static runtime, model-source, association or test reference: `RpBaseAppCallbackState`

### `rp_base_org` — `RpBaseOrgRecord` — **USED** (`database.yml`: MISSING)

Runtime-referenced models and one current caller example each:

- `RpBaseOrgStepUpAuditOutboxDeliveryState` —
  `app/values/step_up_audit_outbox_sources_registry.rb:36`
- `RpBaseOrgStepUpAuditOutboxAttempt` — `app/values/step_up_audit_outbox_sources_registry.rb:35`
- `RpBaseOrgStepUpAuditOutbox` — `app/values/step_up_audit_outbox_sources_registry.rb:33`

Models referenced only through model source/associations and/or tests:
`RpBaseOrgStepUpStateTransition`, `RpBaseOrgStepUpStateStatus`, `RpBaseOrgStepUpState`,
`RpBaseOrgSessionSelection`, `RpBaseOrgSessionAvatarSelection`, `RpBaseOrgSession`,
`RpBaseOrgPrincipal`, `RpBaseOrgOpSessionBinding`, `RpBaseOrgIdentityBinding`,
`RpBaseOrgEventReceipt`

Models with no static runtime, model-source, association or test reference: `RpBaseOrgCallbackState`

### `rp_core_app` — `RpCoreAppRecord` — **ONLY-VIA-MODELS** (`database.yml`: MISSING)

Runtime-referenced models and one current caller example each: None.

Models referenced only through model source/associations and/or tests: `RpCoreAppSession`,
`RpCoreAppPrincipal`, `RpCoreAppOpSessionBinding`, `RpCoreAppIdentityBinding`,
`RpCoreAppEventReceipt`

Models with no static runtime, model-source, association or test reference: `RpCoreAppCallbackState`

### `rp_core_org` — `RpCoreOrgRecord` — **ONLY-VIA-MODELS** (`database.yml`: MISSING)

Runtime-referenced models and one current caller example each: None.

Models referenced only through model source/associations and/or tests: `RpCoreOrgSession`,
`RpCoreOrgPrincipal`, `RpCoreOrgOpSessionBinding`, `RpCoreOrgIdentityBinding`,
`RpCoreOrgEventReceipt`

Models with no static runtime, model-source, association or test reference: `RpCoreOrgCallbackState`

### `rp_edit_org` — `RpEditOrgRecord` — **USED** (`database.yml`: MISSING)

Runtime-referenced models and one current caller example each:

- `RpEditOrgSession` — `app/services/rp_request_authenticator.rb:21`

Models referenced only through model source/associations and/or tests: `RpEditOrgPrincipal`,
`RpEditOrgOpSessionBinding`, `RpEditOrgIdentityBinding`, `RpEditOrgEventReceipt`

Models with no static runtime, model-source, association or test reference: `RpEditOrgCallbackState`

### `rp_palm_app` — `RpPalmAppRecord` — **ONLY-VIA-MODELS** (`database.yml`: MISSING)

Runtime-referenced models and one current caller example each: None.

Models referenced only through model source/associations and/or tests: `RpPalmAppSession`,
`RpPalmAppPrincipal`, `RpPalmAppOpSessionBinding`, `RpPalmAppIdentityBinding`,
`RpPalmAppEventReceipt`

Models with no static runtime, model-source, association or test reference: `RpPalmAppCallbackState`

### `rp_tech_org` — `RpTechOrgRecord` — **ONLY-VIA-MODELS** (`database.yml`: MISSING)

Runtime-referenced models and one current caller example each: None.

Models referenced only through model source/associations and/or tests: `RpTechOrgSession`,
`RpTechOrgPrincipal`, `RpTechOrgOpSessionBinding`, `RpTechOrgIdentityBinding`,
`RpTechOrgEventReceipt`

Models with no static runtime, model-source, association or test reference: `RpTechOrgCallbackState`

### `rp_warp_app` — `RpWarpAppRecord` — **ONLY-VIA-MODELS** (`database.yml`: MISSING)

Runtime-referenced models and one current caller example each: None.

Models referenced only through model source/associations and/or tests: `RpWarpAppSession`,
`RpWarpAppPrincipal`, `RpWarpAppOpSessionBinding`, `RpWarpAppIdentityBinding`,
`RpWarpAppEventReceipt`

Models with no static runtime, model-source, association or test reference: `RpWarpAppCallbackState`

### `rp_warp_org` — `RpWarpOrgRecord` — **ONLY-VIA-MODELS** (`database.yml`: MISSING)

Runtime-referenced models and one current caller example each: None.

Models referenced only through model source/associations and/or tests: `RpWarpOrgSession`,
`RpWarpOrgPrincipal`, `RpWarpOrgOpSessionBinding`, `RpWarpOrgIdentityBinding`,
`RpWarpOrgEventReceipt`

Models with no static runtime, model-source, association or test reference: `RpWarpOrgCallbackState`

### Other configured databases

- `primary` (`ApplicationRecord`) and `search` (`SearchRecord`) have no concrete application models
  assigned directly to them and classify **UNUSED** by direct concrete-model ownership.
- `queue` and `storage` have no app-owned abstract `*Record` classes, so they are outside the
  22-writer model scan.
- Nine `rp_*` writer keys are statically declared but absent from `config/database.yml`:
  `rp_base_app`, `rp_base_org`, `rp_core_app`, `rp_core_org`, `rp_edit_org`, `rp_palm_app`,
  `rp_tech_org`, `rp_warp_app`, and `rp_warp_org`. The config-key status above checks names only.

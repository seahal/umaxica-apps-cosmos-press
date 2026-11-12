# Press surface URL reader retirement

Date: 2026-11-10. HEAD: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`. The worktree already had 1,750
tracked changes. Results include this task's uncommitted edits and that existing worktree; they are
not a clean-HEAD claim. No commit, credential edit, database reset, production deployment or
external configuration change was performed. Test fixture mutations were confined to the existing
test environment.

Scope/acceptance: [spec](../specs/press-surface-url-dependencies/spec.md). Current configuration
explanation: [URL dependencies](../docs/operations/press-surface-url-dependencies.md). Ownership
checked against the Sphere ADR, Press ownership spec and the five drawn route families: Edit ORG and
Info/Docs/News/Help app/com/org are local; Access/Governance/Sphere routes are not.

## Removed readers and definitions

Retired readers were removed together from:

- `lib/config_values_host_family_values.rb`, `config_values_oidc_authority_values.rb`: copied
  Core/Warp/Palm/Tech/ACME host fields, their interpolated selectors, and Visa corporate.
- `app/values/jump_rt_surface.rb`, `oidc_client_registry.rb`,
  `oidc_client_stores_static_client_store.rb`: copied issuer/client origins and cache inputs. Local
  OIDC registration is only Edit; Press acquires no Jump issuer namespace.
- `app/values/fqdn_availability_registry.rb` and development/production host authorization:
  non-Press host slots, aliases and input lists. Historical persisted flag-name mappings remain; no
  feature records were changed.
- `surface_chrome`, `authentication_redirects`, `sign_authority_redirect`,
  `sign_acme_authority_redirect`, `common_redirect` concerns: retired Base completion/navigation
  readers; unsupported completion explicitly refuses rather than choosing another surface.
- Local backchannel classification, OmniAuth host classification and CSP form hosts: no eager
  private Base fields or local Base provider surface. Existing Access protocol boundaries remain.

Removed 22 definition lines from `.env`, 20 from `.env.local`, and 23 from
`.env.container.devcontainer` (65 total), representing these 25 distinct names:

- `PRIVATE_BASE_{SERVICE,CORPORATE,STAFF,NETWORK,DEVELOPER}_URL`
- `PUBLIC_BASE_DEVELOPER_URL`
- `{PUBLIC,PRIVATE}_CORE_{SERVICE,CORPORATE,STAFF,DEVELOPER}_URL`
- `PUBLIC_WARP_{SERVICE,CORPORATE,STAFF}_URL`
- `{PUBLIC,PRIVATE}_PALM_SERVICE_URL`
- `{PUBLIC,PRIVATE}_TECH_STAFF_URL`
- `PUBLIC_VISA_CORPORATE_URL`, `PRIVATE_VISA_{SERVICE,CORPORATE,STAFF}_URL`

No matching definitions remain in those three files or either Compose file. No Compose file needed
an edit. Environment scans emitted names/counts only. Final runtime/test searches found no exact
retired URL inputs, including required fetches; dynamic selectors were also traced and retired.

**Incomplete:** `.github/workflows/ci.yml` is read-only (write failed with errno 30); 44 definitions
of 22 retired names remain. This includes the already-unread `PUBLIC_GUID_SERVICE_URL`. No GUID URL
reader or writable definition existed to remove. No permission workaround or external write was
attempted. Current docs/runbooks were updated, while historical ADR/research content remains.

## Kept with readers and reasons

| Inputs                                                                        | Reader                                                                                                                                                     | Reason                                                                                                    |
| ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `PUBLIC/PRIVATE_AUTH_*`                                                       | `app/controllers/edit/org/application_controller.rb:100`; `app/controllers/concerns/common_redirect.rb:134`; `lib/config_values_host_family_values.rb:166` | Access sign-in and redirect origins; whole family explicitly retained by owner.                           |
| `PUBLIC_BASE_{SERVICE,CORPORATE,STAFF}_URL` and existing unprefixed selectors | `app/values/security_jwt_preference_token_codec.rb:145` (three consecutive realm anchors); `lib/config_values_host_family_values.rb:128`                   | Preserve shared preference registrable-domain classification. Base corporate is not a retired dependency. |
| `PUBLIC_BASE_SERVICE_URL`, `PUBLIC_BASE_STAFF_URL`                            | `app/mailers/email/app/otp_mailer.rb:168`, `app/mailers/email/org/otp_mailer.rb:98`, `app/mailers/concerns/promotional_email_unsubscribe_headers.rb:13,19` | Preserve existing identity-delivery/unsubscribe link contracts; no new mail workflow introduced.          |
| `PUBLIC_VISA_{SERVICE,STAFF}_URL` and existing unprefixed selectors           | `app/controllers/edit/org/application_controller.rb:104`; `app/values/oidc_issuer.rb:49,51`; `app/controllers/concerns/oidc_callback.rb:124`               | Edit needs Access Visa ORG; generic app/org issuer and callback validation remains intact.                |
| `PUBLIC_EDIT_STAFF_URL`, `PRIVATE_EDIT_STAFF_URL`                             | `app/values/oidc_client_stores_static_client_store.rb:26`; `app/values/oidc_client_registry.rb:223`                                                        | Explicit own public/private callback origins and cache invalidation; no literal host fallback.            |
| Press Info/Docs/News/Help app/com/org inputs                                  | `lib/config_values_host_family_values.rb:100-117`; matching `config/routes/{info,docs,news,help}.rb` and development host list                             | All twelve content audiences still have Press routes, including corporate.                                |
| Press private operator-tool inputs                                            | `config/routes/{mission,flipper,blazer,pghero,coverband,swagger}.rb`                                                                                       | Own operator surfaces remain routed.                                                                      |

Explicitly protected workload, sandbox, Vite, enforcement HMAC and planned storage variables were
unchanged. Retained external protocol/domain inputs are not admitted as local Press surfaces.

## Verification and corrections

- Final `bin/rubocop`: **4,447 files, no offenses**.
- Final consolidated affected `bin/rails test` collection: **418 runs, 2,666 assertions, zero
  failures/errors/skips**. It includes all `test/security`, all `test/services/jump_rt`, both OIDC
  registry test files, JWT registry, host-family parsing, OmniAuth, preference codec/model, redirect
  concerns, Edit sign-in/root/dashboard and the six content/Edit/retired route contracts. No
  assertions or tests were skipped to obtain this result.
- Earlier delegated checks: Jump/OIDC 144 tests; redirect concerns 25; middleware 17; JWT registry
  22; refresh invariants 4. Their final relevant cases are included in the consolidated collection.
- Wider initial collection: 418 tests, two failures and one error. Corrected the task-caused missing
  private Edit registration and migrated the obsolete Core refresh fixture to a real Edit operator
  grant, preserving actual replay/revocation checks. The unchanged Edit sign-in integration passes
  after that correction. No retired client registration was restored.
- Separate, still-failing test: `test/integration/oidc_rp_logout_edit_return_test.rb:108` expects an
  ID-token hint. Existing `oidc_rp_logout_launcher.rb:45` explicitly makes OP logout a no-hint
  browser step. This task did not modify either file. That source/test mismatch was reported,
  excluded from the final affected collection, and not silently corrected as part of URL cleanup. No
  clean-baseline run was used to classify it further.
- `RAILS_ENV=development bin/rails runner -`, with all retired name patterns removed from inherited
  ENV: all 13 owned `/health/startup` requests returned **200**; six retired host aliases returned
  **403** and had no availability slot; only `edit-org-ww` registered; local Jump issuer list empty.
  Requests exercised the real development Rack stack in process. One diagnostic initially called
  nonexistent registry method `all`; using the public `client_ids` API completed the check.
- Scoped `git diff --check`: passed. No full `bin/ci` or production-environment boot was run.

Gateway cryptographic tests isolate exact fixture origin-to-identity resolution, retain the real
directed-edge policy and signature/time/URL/JWKS assertions, and do not claim a deployed Press
return edge. Actual Press policy rejects the foreign graph. Existing foreign-client grants were not
migrated: operations requiring a retired local endpoint fail closed; any retained foreign records
require a separate owner-reviewed data disposition. Restart existing processes/containers to discard
inherited obsolete variables. CI cleanup remains open.

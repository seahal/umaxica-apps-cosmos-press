# Unified Enforcement Rollout Runbook

> **Route boundary update (2026-11-10):** The local Base ORG enforcement console was removed. This
> procedure covers persisted enforcement records, migrations, secrets, and scheduled jobs; it does
> not provide an HTTP workflow for creating or reviewing cases.

This is the step-by-step operational companion to `adr/unified-enforcement.md` (design and Decision
Log) and `docs/security/unified-enforcement.md` (operational contract). Read those first for
rationale; this document only covers deployment mechanics, provisioning order, and verification
steps.

## Current status

The 2026-11-10 surface hard reset removed the local Auth and Base controller trees, including the
enforcement case console. Press currently serves no local enforcement case creation or review route.
Enforcement models, migrations, identifier digest code, triggers, and recurring jobs remain; no
database was dropped. The accepted `adr/unified-enforcement.md` still describes the former route
scope and is not amended by this report. Treat that route description as historical until its owner
updates it.

This runbook now covers persisted enforcement data, migration state, secret provisioning, and
scheduled cleanup/reconciliation. It does not describe a local case-management workflow. Production
secret provisioning has not been performed outside `compose.yaml` development settings.

## Secret provisioning order

Two secrets gate the live enforcement paths:

- `ENFORCEMENT_APP_IDENTIFIER_HMAC_KEY`
- `ENFORCEMENT_ORG_IDENTIFIER_HMAC_KEY`

Each is read by `EnforcementIdentifierDigest.key_for(realm)`
(`app/lib/enforcement_identifier_digest.rb`), which checks `Rails.app.creds` (encrypted credentials,
then ENV) and raises `KeyError` — by design, per
`.agents/harnesses/rules/generic/no-silent-fallback.mdc` — if the realm's key is absent. This is
fail-closed: an unprovisioned key does not silently disable enforcement, it 500s the request path
that needed it.

**Provisioning must happen before code that reads these keys reaches an environment**, for every
environment in turn (never all at once, and never after deploying the code):

1. Generate two independent, high-entropy secrets (do not reuse `EMAIL_ADDRESS_HMAC_SALT` /
   `TELEPHONE_NUMBER_HMAC_SALT`, or any secret across realms — D6 requires per-realm, dedicated keys
   so a compromised login-lookup key cannot double as an offline oracle over the enforcement list,
   and vice versa).
2. Add them to the target environment's actual secret store (Rails encrypted credentials or the real
   ENV injection mechanism for that environment — for this repository's dev containers, that is
   `compose.yaml`'s `environment:` block, already updated with development-only defaults; production
   has its own separate mechanism outside this repository's checked-in files).
3. Restart/redeploy so every app process picks up the new value. Confirm with a Rails console in
   that environment: `EnforcementIdentifierDigest.key_for("app")` and
   `EnforcementIdentifierDigest.key_for("org")` must return non-nil strings, not raise.
4. Only after both keys are confirmed present in an environment, deploy application code that calls
   `EnforcementIdentifierDigest`/`EnforcementIdentifierGate` to that environment.

Deploying the gating code before the keys exist in that environment causes each signup, attachment,
and future recovery request that reaches the gate to raise `KeyError` and return a server error.

## Migration order

Apply per-realm `*_zenith_migrate` migrations (Phases 2, 6, 7) before `*_ticket_migrate` and
`chronicle_migrate` migrations (Phases 1a, 3) only matter relative to each other, not to the zenith
migrations — there is no cross-database FK (D7), so no database's migration is blocked on another's.
`db:migrate` run against a fresh environment in any order converges; there is no manual sequencing
step required beyond the standard `bin/rails db:migrate` per configured role, which this
repository's `db:test:prepare` override already demonstrates for the test environment.

Trigger migrations (Phase 8, D20) are scoped to specific tables. Do not migrate a
`permanently_frozen`-capable trigger onto `client_google_identities`, `client_apple_identities`, or
`client_external_identities` — D20 explicitly defers those until the common-storage cutover
(`ExternalAuthentication::IdentityRepositoryFactory.common_storage?`) is complete everywhere. A
CHECK constraint already prevents `permanently_frozen` on `google`/`apple` Method Effects
independent of trigger presence, so this is a defense-in-depth ordering note, not a hard blocker.

## Verification checklist per environment

Run after secret provisioning and migration, before considering that environment live:

1. `EnforcementIdentifierDigest.key_for(realm)` returns non-nil for `app` and `org`.
2. `bin/rails db:migrate:status` shows zero pending migrations across all configured database roles.
3. Run the retained enforcement regression tests in CI:
   `test/operations/enforcement_case_apply_authority_test.rb`,
   `test/models/enforcement_triggers_test.rb`, `test/lib/enforcement_identifier_digest_test.rb`, and
   `test/policies/operator_capability_policies_test.rb`. These cover persisted behavior and policy;
   they do not establish an HTTP case-management route.
4. `test/models/enforcement_triggers_test.rb` passes (confirms both currently-built triggers —
   `client_emails` permanently_frozen protection, `clients` hard-delete protection — reject the
   raw-SQL/`delete_all` paths they guard).
5. Recurring jobs `EnforcementExpiryJob` and `EnforcementReconciliationJob` are present in
   `config/recurring.yml` for that environment and the scheduler is actually running them (check the
   job runner's own operational dashboard, not just the YAML). `EnforcementReconciliationJob` must
   be able to rediscover a persisted appeal after a failed Case-ending or Chronicle side effect; a
   missing queue execution is not evidence that the appeal decision was rolled back.
6. Do not attempt a local console smoke test: Press serves no enforcement case-creation or review
   route. Case changes require the owning external operator authority until a separately approved
   surface is introduced.

## Known remaining scope (not blocking this rollout, tracked for later work)

- No Google/Apple Identifier Effect trigger (D20, deferred to post-cutover).
- Realm-scoped operator permissions (D13) are implemented as operator capability grants
  (`adr/operator-capability-authorization.md`, 2026-09-26): `EnforcementCasePolicy` checks the
  realm's read, apply, approve, release, and review_appeal capabilities; the org realm has none.
- 14 of the ~16 planned per-table triggers remain unbuilt (Phase 8 note in the plan's Progress Log):
  `*_telephones`, `*_passkeys`, `*_secret_credentials` across the live `app` and `org` realms,
  `client_totp_credentials`, `operator_entra_identities`, and hard-delete protection on `visitors`
  and `operators`. Each follows the exact pattern already proven on `client_emails` and `clients`
  (use `clock_timestamp()`, never `now()`, in any time-predicate trigger; test raw-SQL failure paths
  on the connection that owns the table, not `ActiveRecord::Base.transaction`).
- No account-recovery or reactivation controller exists in this codebase at all today, so
  `recovery_blocked` and `reactivation_blocked` Principal/Identifier Effect gates have no live call
  site. Building such a controller is out of scope for the enforcement rollout itself.
- Production secret provisioning (the store update in step 2 above) is an infrastructure action
  outside this repository's checked-in files and outside the scope any single code change can
  perform; it is a manual operational step for whoever owns each environment's secret store.

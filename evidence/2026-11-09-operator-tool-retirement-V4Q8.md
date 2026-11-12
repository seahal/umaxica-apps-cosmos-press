# Press operator-tool retirement

## Revision and worktree

- Full `HEAD`: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`.
- The worktree had unrelated uncommitted changes before this work. They were preserved; no commit
  was made. Test results therefore describe this shared worktree, not a clean checkout.
- `Gemfile` and `Gemfile.lock` were snapshotted before each dependency removal. The snapshot before
  the Rails DB removal had SHA-256
  `f99d956e1034be3b1862405ad4a12441b9cc5c41d284b323f9198bc8ecb1b0d9` and
  `045fd71081b7c105749d848b5ab6595643144cb72344bded4ebad028a55f1213`. The snapshot before the
  Performance removal had SHA-256 `b5c75d2b56488b2a8095e56e5cee8c83af0e82433e5e808ee0fd0e57e77580dd`
  and `2d6be5a6e334460ec84c1937a58a45d3e713728d9cbabb5fa0e0189014431b76`.
- Final `Gemfile` SHA-256: `96a36d020a4f357305f38bfd8abe3b8ad33eb31fd175484a2a04c8f14a29aea8`. Final
  `Gemfile.lock` SHA-256: `16a2edc1f6fe1f9cf2b2547816e4ce3a6a9b6c8041e177c074e487ed4d6c3905`.

## Changes

- Removed `rails_db` and `rails_performance` from the development Gemfile group. The Rails pin and
  other dependencies, including `msgpack`, remain unchanged.
- Ran `bundle install --local` after each removal. The final lockfile comparison against the
  pre-removal snapshot found only these removed specs: `browser 6.2.0`, `kaminari 1.3.2`,
  `kaminari-actionview 1.3.2`, `kaminari-activerecord 1.3.2`, `kaminari-core 1.3.2`,
  `rails_db 2.5.0`, `rails_performance 1.6.0`, `ransack 6.0.1`, and `simple_form 5.4.1`. No specs
  were added or version-changed. The removed direct dependencies are only `rails_db` and
  `rails_performance`; `browser` was a dependency of `rails_performance`.
- Removed the Performance route draw, route file, initializer, sanitizer/resilience libraries,
  sanitizer test, FQDN slot, host aliases, environment-template variables, and Valkey
  responsibility. The `/rails/performance` forbidden-mount invariant remains. `rails_db` was also
  removed from the mounted-engine invariant, while `/rails/db` remains forbidden.
- Updated current operator-surface, cache-policy, and Valkey topology documentation, and added
  retirement amendments to the environment-construction and diagnostic-surface ADRs. The environment
  variable backlog records this scoped, owner-directed removal while leaving its repository-wide
  inventory not started. Historical rationale remains present and is marked as historical.
- Removed the Rails Performance-only variables from the tracked `.env.container.devcontainer`
  template without printing their values. No credentials-store value was rotated.
- `.devcontainer/compose.yaml` and `.github/workflows/ci.yml` were not written. The latter was clean
  in the worktree; the former was already modified before this work. A value-redacted proposal is
  stored at `/tmp/press-operator-tool-retirement/protected-files-proposal.redacted.patch` and
  included below. Because RHS values are redacted, it is a review proposal, not an apply-ready
  patch.
- No Cloudflare or other external service was changed. The owner follow-up in the backlog remains.

### Protected-file proposal (values redacted)

```diff
--- a/.devcontainer/compose.yaml
+++ b/.devcontainer/compose.yaml
@@ -223 +222,0 @@
-          - performance.core.dev.localhost
@@ -230 +228,0 @@
-          - performance.umaxica.dev
@@ -246 +244 @@
-      # Diagnostic / compatibility instance (rails_performance, Coverband, and
+      # Diagnostic / compatibility instance (Coverband and
--- a/.github/workflows/ci.yml
+++ b/.github/workflows/ci.yml
@@ -337,2 +336,0 @@
-      PUBLIC_PERFORMANCE_URL: <redacted>
-      PRIVATE_PERFORMANCE_URL: <redacted>
@@ -343,2 +340,0 @@
-      RAILS_PERFORMANCE_USERNAME: <redacted>
-      RAILS_PERFORMANCE_PASSWORD: <redacted>
@@ -349 +344,0 @@
-      RAILS_PERFORMANCE_ENABLED: <redacted>
@@ -621,2 +615,0 @@
-      PUBLIC_PERFORMANCE_URL: <redacted>
-      PRIVATE_PERFORMANCE_URL: <redacted>
@@ -627,2 +619,0 @@
-      RAILS_PERFORMANCE_USERNAME: <redacted>
-      RAILS_PERFORMANCE_PASSWORD: <redacted>
@@ -633 +623,0 @@
-      RAILS_PERFORMANCE_ENABLED: <redacted>
```

## Verification

- `RAILS_ENV=test bin/rails runner 'puts Rails.version'`: passed; Rails `8.2.0.alpha`.
- `RAILS_ENV=test bin/rails routes`: passed; zero `/rails/db` or `/rails/performance` route matches.
- `bin/rails test test/security`: 114 runs, 598 assertions, 0 failures, 0 errors, 0 skips. This
  includes `MountedEngineInvariantTest`.
- `bin/rails test test/lib/umaxica/valkey test/controllers/branch_coverage_batch40_line_push_test.rb`:
  19 runs, 100 assertions, 0 failures, 0 errors, 0 skips.
- `bin/rails test test/integration/routes/retired_surface_host_refusal_test.rb`: 2 runs, 110
  assertions, 0 failures, 0 errors, 0 skips. The retired Performance host root returns 404 in the
  test environment.
- `bin/rubocop`: 4,447 files inspected, no offenses.
- `git diff --check`: no issues.
- A scoped search found no Rails Performance implementation, gem, constant, or environment-variable
  references in `app/`, `config/`, `lib/`, `Gemfile`, `Gemfile.lock`, root `compose.yaml`, or the
  tracked environment template. The only remaining test references are the retired hostname in the
  404 assertion. Historical ADR/backlog references and the forbidden path invariant are retained.

## Development database check and limitation

- `getent hosts primary` succeeded. A read-only query was attempted using the development
  `op_base_app` connection configuration (`development_op_base_app_db`) from a test-mode runner and
  an explicit `BEGIN TRANSACTION READ ONLY`. It stopped before reading tables with
  `ActiveRecord::NoDatabaseError`. No database was created, prepared, reset, or written by this
  query.
- Two follow-up read-only connection checks during final review also raised
  `ActiveRecord::NoDatabaseError` for the configured database.
- The required rows are migration-owned: `client_sign_out_flow_kinds` IDs `0, 10, 20, 30`;
  `client_sign_in_flow_states` IDs `10, 20, 30, 40, 50, 60, 65, 70, 80, 100, 900, 910, 920, 930`;
  `client_session_limit_resolution_states` IDs `10, 20, 100, 910, 920`; and
  `client_sign_up_flow_statuses` IDs
  `10, 20, 30, 35, 36, 38, 40, 60, 70, 80, 100, 900, 910, 920, 930`. Their presence cannot be
  confirmed while the configured development database is absent. No rows were inserted. This check
  is pending an already-prepared development database; database creation or preparation was not
  authorized.
- One earlier command, `RAILS_ENV=development bin/rails runner` to enumerate connection names,
  booted the development app before its initializer side effect was noticed. At
  `config/initializers/preference_reference_defaults.rb:26`, development boot calls
  `ensure_defaults!` for nine app/com/org preference reference classes; that method can insert
  missing fixed IDs. Whether that boot inserted any such preference rows is unknown because no
  before/after counts were collected. No rollback or cleanup was attempted. No further development
  app boot was performed. This possible side effect did not target the four `op_base_app` tables
  listed above.
- Development-mode route enumeration and a live development HTTP request to the retired host remain
  unverified. Static route/config inspection, the test-mode route set, and the 404 integration test
  passed. No local listener was present on ports 3000, 3001, or 3002. The development database
  limitation and the initializer side effect prevented a safe app boot without risking another
  development DB write.

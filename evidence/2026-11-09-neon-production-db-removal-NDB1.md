# Neon Production Database Configuration Removal

Date: 2026-11-09

Decision: The 2026-11-09 amendment to `adr/staging-aurora-postgresql-topology.md` withdraws the Neon
production configuration until a provider is selected.

Repository HEAD: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`

The worktree already contained unrelated uncommitted changes. The three files changed for this task
were clean before editing. No commit was created. Tests ran against the current combined worktree.

## Changes

- Removed the `production:` database section, the `production_value` lambda, its production-only SSL
  entries, and all `NEON_*` reads from `config/database.yml`.
- Removed the production-only database name derived for RP cells. Development and test configuration
  text remained byte-for-byte unchanged; pre-edit and post-edit section hashes matched:
  - Development: `79e1cf7305d07fc92471f4d280a25196ba127c8490369a88f21d84522f723e79`
  - Test: `5a29e7aaa2ace8ab0d5847d59b39adc5241043a4cb15a6150cbe48fbbd811ec1`
- Added an early production boot guard in `config/application.rb`. It raises
  `ActiveRecord::AdapterNotSpecified` with `production database is not configured`, before unrelated
  production prerequisites can obscure the missing database decision.
- Removed the Neon-specific assertions from `test/unit/database_password_config_test.rb`; the two
  existing queue-pool and connection-shape tests remain.

## Verification

- `RAILS_ENV=test bin/rails runner 'puts Rails.version'`: passed, Rails `8.2.0.alpha`.
- `RAILS_ENV=development bin/rails runner 'puts Rails.version'`: passed, Rails `8.2.0.alpha`.
- `RAILS_ENV=production bin/rails runner 'puts Rails.version'`: exited 1 with
  `ActiveRecord::AdapterNotSpecified: production database is not configured`.
- `git grep -iw neon -- config/ app/ lib/ test/`: zero matches. A separate tracked Ruby/Rake source
  scan also found zero `NEON_*` references.
- `bin/rails test test/unit/database_password_config_test.rb`: **2 runs, 17 assertions, 0 failures,
  0 errors, 0 skips**.
- Full non-system suite, using all 2,383 test files as explicit arguments and `PARALLEL_WORKERS=1`:
  **17,149 runs, 149,392 assertions, 301 failures, 72 errors, 0 skips**. Explicit paths bypassed
  Rails' `test:prepare` task; one worker also bypassed parallel test database cloning. The `primary`
  hostname resolved. No database creation, reset, or deletion task was invoked.
- Failure and error names, exception classes, and first repository frames are saved outside the
  repository at `/tmp/2026-11-09-neon-production-db-removal-tests.txt`.
- Compared with `R9P1`'s earlier pre-GUID-removal report (17,164 runs, 304 failures, 67 errors), 316
  of the current 322 unique failing test names were already listed; six current names were absent
  and four earlier names no longer fail. The six absent names are in files outside this task's diff:
  five `DbscHeaderBoundaryTest` errors first reaching `lib/runtime_role_route_guard.rb:16`, and one
  `ClientSecretAuditDeliveryJobTest` failure at
  `test/jobs/client_secret_audit_delivery_job_test.rb:299`. They were not changed here.
- `bin/rubocop config test`: passed, 2,507 files inspected, no offenses.
- `git diff --check`: passed.
- Development/test database settings remained unchanged. No database/schema files, container files,
  compose files, or `.env*` files were changed. No database was created, reset, or deleted, and no
  external service was changed.

# Rails revision pin verification

- Date: 2026-11-09.
- Repository: Cosmos Press; HEAD `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`.
- Results include uncommitted changes. The worktree already contained unrelated edits, including
  Gemfile.lock dependency changes; those were preserved. This task changes only Gemfile, the Rails
  source selection in Gemfile.lock, and this evidence record. No commit was created.
- Rails was pinned to `9ba8b1edeeacccb1ff5d2497432242eeddf48aed` to avoid the
  omniauth-rails_csrf_protection `config_delegate` boot failure.

## Dependency verification

- Saved the starting Gemfile and lockfile to `/tmp/press-rails-pin-R9P1/` as `Gemfile.before` and
  `Gemfile.lock.before`; saved the pre-existing lockfile diff as `lock-preexisting.diff`.
- `bundle install --local`: exit 0. No network fetch or bundle update was needed.
- Exact comparison against the saved lockfile passed: only Rails revision changed from
  `ad04193d6778f8b88311133e3a21846353da41fc` to the pin, and `branch: main` became
  `ref: 9ba8b1edeeacccb1ff5d2497432242eeddf48aed`. No other gem versions changed in this task.
- `RAILS_ENV=test bin/rails runner 'puts Rails.version'`: exit 0, output `8.2.0.alpha`.
- `bin/rubocop Gemfile`: exit 0, one file inspected, no offenses.
- `git diff --check`: exit 0.
- The Governance reference supplied by the user was not available at its corresponding
  `/home/global/Projects/ghq/` path in this executor.

## Test execution and blocker

- `getent hosts primary` resolved to `10.89.8.3` (`primary.dns.podman`).
- `bin/rails test`: exit 1 before test execution, with `ActiveRecord::NoDatabaseError`:
  `test_publishing_db` does not exist. First repository frame: `test/test_helper.rb:51`; loading
  caller: `test/adapters/avatar_authority_client_sensitive_mutations_test.rb:3`.
- Authorized preparation was attempted with `RAILS_ENV=test bin/rails db:test:prepare`. It exited 1
  with `Umaxica::TestEnvironment::ConfigurationError`: configured PostgreSQL test databases are
  missing. First repository frame: `lib/umaxica/test_environment/database_safety.rb:77`.
- No test methods ran; no Minitest totals or individual failing test names were emitted.
  Passing/failing/error counts remain unavailable. Full-suite completion acceptance is blocked.
- Failure/error inventory outside the repository: `/tmp/press-rails-pin-R9P1/test-failures.md`.
  Command output is retained alongside it as `rails-test.log` and `db-test-prepare.log`. These
  session-local files may not survive executor cleanup.
- These are environment blockers, not demonstrated Rails-pin regressions. No unrelated failures were
  repaired. Database configuration and connection destinations were not changed; no database was
  created, reset or deleted. Creating the missing databases requires the user's explicit approval.

## Continuation after database creation approval

The user explicitly approved creating the missing test databases on 2026-11-09.

- `RAILS_ENV=test bin/rails db:create`: exit 0; created configured writable test databases.
- The next preparation attempt still rejected missing replica test databases at
  `lib/umaxica/test_environment/database_safety.rb:77`. Rails' normal create task excludes replicas.
- Created the configured replica test databases via `ActiveRecord::Tasks::DatabaseTasks.create`
  after `DatabaseSafety.verify!` on every effective test configuration. The first attempt retained
  the replica flag and was refused with `ActiveRecord::ReadOnlyError`; the successful administrative
  creation call omitted only that flag in its in-memory argument. No repository database setting,
  host, port, username or database name was changed.
- `RAILS_ENV=test bin/rails db:test:prepare`: exit 0. Existing preparation scope covered all 26
  writers; migrations ran without importing dump receipts. No development database or volume was
  deleted or reset.
- `bin/rails test`: completed, exit 1, seed/output retained in
  `/tmp/press-rails-pin-R9P1/rails-test-after-prepare.log`.
- Final result: **17,164 runs, 149,566 assertions, 304 failures, 67 errors, 0 skips**; elapsed test
  time 1098.860332 seconds, 16 workers.
- All 371 failure/error entries, with test names, exception classes and first repository locations,
  are saved in `/tmp/press-rails-pin-R9P1/test-failures.md`. Extracted totals match Minitest totals.
  No individual failure was repaired. Their pre-existing status cannot be established because the
  prior Rails revision could not boot; this run is the post-pin baseline.
- Repeated `bin/rubocop Gemfile`, `git diff --check`, and exact Rails-only comparison with the saved
  starting lockfile all passed.
- This full baseline finished before any subsequent GUID retirement or operator-host changes. Those
  changes and their scoped verification are recorded separately.

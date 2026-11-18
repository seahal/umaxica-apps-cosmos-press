# Rails test environment

Rails tests use explicit test-only PostgreSQL databases and Valkey logical databases declared in
`config/valkey.yml`. A test process must not inherit the development host or the development Valkey
databases.

Canonical Compose services are `valkey-cache` and `valkey-kvs`. Test cache does not connect to
Valkey; it uses `ActiveSupport::Cache::MemoryStore`. Rate-limit and auth-state use `valkey-kvs`
logical DBs 4 and 6.

```bash
bundle exec rails test
bun vitest run
```

Orchestration supplies `VALKEY_KVS_HOST`. Do not export `VALKEY_TEST_HOST`, `CACHE_REDIS_URL`,
`RATE_LIMIT_REDIS_URL`, `AUTH_STATE_REDIS_URL`, or a run namespace before those commands. Rails
generates `VALKEY_NAMESPACE_RUN_ID` when it is absent.

`config/database.yml` fixes every test database to `primary:5432` as `root` (password
`development`); no environment variable selects the test PostgreSQL target, so an exported variable
cannot redirect a destructive preparation. `Umaxica::TestEnvironment::DatabaseSafety` holds the same
fixed values and validates every effective test database configuration before opening Active Record
connections. `DATABASE_URL` and other database URL overrides cannot silently redirect a test
connection to a non-test database.

Application auth-state and rate-limit keys include the run and worker identifiers. Parallel Minitest
workers share logical DBs 4 and 6 and isolate keys by namespace (`<run-id>:<worker-id>:…`). Cleanup
uses prefix SCAN + DEL. `FLUSHDB` and `FLUSHALL` are forbidden.

The test boundary prevents provider delivery: Action Mailer uses the `:test` delivery method, the
SMS provider is `test`, and Turnstile is replaced by `TurnstileVerifierStub`. An unstubbed Turnstile
call raises a test-boundary error rather than invoking Cloudflare. Faraday requests are blocked
unless the test uses `OutboundHttpStub` (or another explicit test adapter) for the duration of the
request.

For a standalone Puma server exercised by TypeScript Playwright and Chromium, see
[Rails browser E2E](rails-browser-e2e.md). That command uses the ordinary configured test databases
and enables real CSRF only in its browser-server process. Neither command requires a PostgreSQL
manifest or per-run database fleet. Both share a process lock and must not run concurrently.

## Rails System Test

`test/application_system_test_case.rb` configures Rails system tests with Capybara's Playwright
Chromium driver, following Cosmos Access. Tests under `test/system/` should require
`application_system_test_case` and inherit from `ApplicationSystemTestCase`. The default browser
host is `PRIVATE_INFO_SERVICE_URL`, mapped to loopback in Chromium; Capybara includes its
dynamically allocated server port. Tests for another Press surface must explicitly select that
surface's host and configure browser resolution for it.

The existing `test_helper.rb` supplies database safety, fixtures, Vite builds, the process lock, and
Valkey isolation. Select a single worker before loading the helper:

```bash
RAILS_ENV=test PARALLEL_WORKERS=1 \
  PLAYWRIGHT_CLI_EXECUTABLE_PATH=./node_modules/.bin/playwright \
  bin/rails test:system
```

Install the locked JavaScript dependencies and the matching Playwright Chromium build before
execution. The explicit CLI path avoids an implicit download through `npx`. Alternatively, set
`PLAYWRIGHT_CHROMIUM_EXECUTABLE=/usr/bin/chromium` to use an installed browser with Chromium's
sandbox enabled. Set `RUBY_DEBUG_ENABLE=0` when unattended execution would otherwise start the Ruby
remote debugger.

System tests use the ordinary test environment's CSRF configuration. Keep `RAILS_BROWSER_E2E` unset;
the separate TypeScript browser-server workflow owns that opt-in. Use `bin/rails test` for ordinary
tests and coverage selection; explicitly selecting `test/` also discovers system tests once
scenarios are added. Before adding scenarios, update any coverage command that still selects
`test/`, including `config/ci.rb` and the GitHub workflow. Automatic browser CI jobs and system-test
scenarios are outside this configuration-only change.

Failure screenshots are saved in `tmp/screenshots/` and diagnostics in `log/test.log`. Review these
for sensitive page data before sharing. Browser-wide external-network blocking is not configured;
provider-backed scenarios need explicit network isolation. This setup has not been executed in
Press. Dependency installation, browser availability, Ruby-client/CLI compatibility, and runtime
behavior remain unverified.

## First local run

Start the checkout’s Compose stack and install the host dependencies using the
[README](../../README.md). For an empty test cluster, create and migrate the test databases before
running the suite.

```sh
RAILS_ENV=test bin/rails db:create
RAILS_ENV=test bin/rails runner '
  puts ActiveRecord::Base.configurations.configs_for(env_name: "test", include_hidden: true)
    .select(&:replica?).map(&:database)' |
  while read -r db; do
    PGPASSWORD=development createdb -h "$PWD/tmp/pg" -U root "$db"
  done
RAILS_ENV=test bin/rails db:test:prepare
bin/rails test
```

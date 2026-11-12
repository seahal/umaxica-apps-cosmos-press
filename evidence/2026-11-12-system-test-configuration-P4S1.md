# Press Rails system-test configuration

- Revision: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`.
- Uncommitted changes affect this configuration. The worktree already contained substantial changes,
  including dependency removals in `package.json` and `bun.lock`; these were preserved.
- Inspected Cosmos Access's `test/application_system_test_case.rb`, dependency declarations,
  test-environment documentation, and `evidence/2026-11-12-rails-system-test-S4M1.md`.
- Added the equivalent Playwright system-test base class using Press's Info host instead of Access's
  Auth host. Required single-worker execution and explicit CLI configuration are retained.
- Added the Playwright CLI declaration and copied its two existing resolved lock entries from Cosmos
  Access (1.64.1). No dependency resolution or installation was executed.
- Added configuration and execution instructions to `docs/operations/test-environment.md`.
- Verification was limited to reading configuration and reviewing changed content, as requested.
  Tests, lint, browser installation, Rails startup, database setup, and containers were not run.
- No scenarios or automatic CI gates were added. Existing coverage commands selecting `test/` need
  to use ordinary `bin/rails test` before browser scenarios are introduced.
- Runtime readiness, browser availability, and Ruby-client/CLI compatibility remain unverified.

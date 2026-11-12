# Rails public and protected method coverage completion

## Revision and worktree

- HEAD: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`.
- Extensive uncommitted work from earlier tasks was present and preserved.
- This coverage pass changed tests and evidence only. No application implementation, CI, or coverage
  threshold was changed.
- The prior 99.92% measurement is recorded in `2026-11-12-rails-public-method-coverage-R8J4.md`.

## Public and protected method audit

A Ruby Coverage preloader started measurement before Rails boot. The audit joined SimpleCov method
entries to Ruby method source locations and visibility.

Rails eager loading found 1,254 public and 29 protected methods. Eight RuboCop callback methods were
not represented in the Rails-only visibility map; source inspection identified `on_class`,
`on_module`, `on_sclass`, and `on_block` as four public callbacks, and `check_body`,
`section_modifier?`, `declared_names`, and `register` as four private methods. All four public
callbacks were covered. The audited public/protected total is **1,287**.

The final measurement found **1,287/1,287 public or protected methods executed: 100%**. The gap
report was empty. This measures method entry coverage; it does not claim 100% branch, line, or
private-method coverage.

## Tests added or extended

- Added `test/controllers/edit/org/api/v0/publishing/action_methods_boundary_test.rb` for the eight
  API actions. Routed requests still stop at the explicit unavailable response, covered by the
  existing all-cell route test. Direct action calls exercise their own first rejection using either
  a missing operator (real policy denies) or an unmapped cell (rejected before a query). No
  application authentication code was changed.
- Extended `test/services/jump_rt/issuer_test.rb` to construct an issuer under a test-local
  namespace-normalizer stub and invoke its public `call` with an invalid destination. The
  destination guard returns before signer configuration is consulted. The existing test that Press
  rejects every issuer namespace remains in place; this does not add a Press signing namespace or
  claim token issuance works here.
- Extended `test/models/actor_test.rb` to execute `Actor::StepUp.null`. The method currently raises
  `NameError` for `Actor::NULL`; the test labels and records that existing defect, rather than
  treating it as a valid null-sentinel result. The implementation was not changed.

Focused verification passed:

- The Jump RT issuer test file: **7 runs, 28 assertions, 0 failures, 0 errors, 0 skips**.
- The API action, route-boundary, actor, and forbidden-pattern tests: **51 runs, 202 assertions, 0
  failures, 0 errors, 0 skips**.
- RuboCop passed for all three changed test files.

## Full Minitest run

All test cases completed: **3,700 runs, 42,380 assertions, 0 failures, 0 errors, 0 skips**.

The `bin/rails test` process exited with status 2 after SimpleCov reported the existing overall
thresholds below target. Global totals were 94.41% line, 64.83% branch, and 94.87% all-method
coverage, against unchanged thresholds of 98%, 93%, and 97%. These totals include private methods
and are separate from the 100% public/protected method-entry audit.

Commands:

```bash
POSTGRESQL_TEST_PREPARE_DATABASES=test_primary_db,test_publishing_db,test_rp_edit_org_db,test_chronicle_db,test_queue_db,test_storage_db \
COVERAGE=true RAILS_ENV=test RUBYOPT=-r/tmp/codex_simplecov_boot.rb PARALLEL_WORKERS=1 \
bin/rails test

PUBLIC_COVERAGE_JSON=/tmp/codex-public-coverage/coverage.json RAILS_ENV=test \
bundle exec rails runner /tmp/public_method_coverage.rb

bin/rubocop \
  test/controllers/edit/org/api/v0/publishing/action_methods_boundary_test.rb \
  test/models/actor_test.rb \
  test/services/jump_rt/issuer_test.rb
```

The previous evidence file preserves the earlier partial measurement; this record contains the
completed measurement and its remaining implementation defect disclosure.

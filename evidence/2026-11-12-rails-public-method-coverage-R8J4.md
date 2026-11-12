# Rails public and protected method coverage update

## Revision and worktree

- HEAD: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`.
- The worktree had extensive uncommitted changes from earlier tasks. They were preserved.
- This update adds tests and this evidence record only; no application implementation, CI, or
  coverage threshold was changed.
- Earlier measurement and work are recorded in `2026-11-12-rails-public-method-coverage-7K2D.md`.

## Coverage result

The audit found 1,254 loaded public instance methods and 29 protected methods. Source inspection
identified four public RuboCop callbacks and four private methods that the Rails-only method
inventory could not load; the four public callbacks were covered. The audited total is therefore
1,287 public or protected methods.

The final report executed 1,286 of 1,287 audited methods: **99.92%**. The only uncovered method is
`JumpRtIssuer#call` in `app/lib/jump_rt_issuer.rb:36`.

`JumpRtSurface.normalize_namespace` rejects every namespace in Press during
`JumpRtIssuer#initialize`. Consequently, no normally initialized Press issuer can reach `#call`. The
test suite continues to verify that all supplied issuer namespaces are rejected. I did not
manufacture an uninitialized issuer in a test merely to raise the coverage count.

`Actor::StepUp.null` is now executed by a characterization test. It raises `NameError` for
`Actor::NULL`; this is an existing implementation defect, not a desired null-sentinel contract. The
test makes the observed failure explicit and must be replaced if the implementation is later
corrected. Production implementation changes were outside this task.

## Test changes

- Added `test/controllers/edit/org/api/v0/publishing/action_methods_boundary_test.rb`. It invokes
  the eight previously uncovered API actions directly with an absent operator or an unmapped
  Publishing cell. The real authorization path rejects operator-less index/create calls; other
  actions reject the unmapped cell before a query. No authorization callbacks are skipped or
  stubbed. Existing routed tests still verify the explicit HTTP 503 boundary for all twelve cells.
- Added the `Actor::StepUp.null` failure characterization to `test/models/actor_test.rb`.
- Focused verification: **51 runs, 202 assertions, 0 failures, 0 errors, 0 skips**.
- RuboCop passed for both changed test files.
- The security forbidden-pattern guard passed as part of focused verification.

## Full Minitest run

All tests completed: **3,699 runs, 42,379 assertions, 0 failures, 0 errors, 0 skips**. The
`bin/rails test` process exited with status 2 after SimpleCov reported its existing overall
thresholds below target; the test cases themselves passed.

SimpleCov totals were 94.41% line, 64.94% branch, and 94.77% all-method coverage, against unchanged
thresholds of 98%, 93%, and 97%. Those global totals include private methods and are separate from
the public/protected audit above.

The full run used a Ruby Coverage preloader so measurement started before Rails boot:

```bash
POSTGRESQL_TEST_PREPARE_DATABASES=test_primary_db,test_publishing_db,test_rp_edit_org_db,test_chronicle_db,test_queue_db,test_storage_db \
COVERAGE=true RAILS_ENV=test RUBYOPT=-r/tmp/codex_simplecov_boot.rb PARALLEL_WORKERS=1 \
bin/rails test

PUBLIC_COVERAGE_JSON=/tmp/codex-public-coverage/coverage.json RAILS_ENV=test \
bundle exec rails runner /tmp/public_method_coverage.rb

bin/rubocop \
  test/controllers/edit/org/api/v0/publishing/action_methods_boundary_test.rb \
  test/models/actor_test.rb
```

## Remaining limitation

The target remains below 100% by one public method. Reaching `JumpRtIssuer#call` through the normal
public API requires a Press signing namespace, which Press intentionally does not own. Covering it
would require changing implementation ownership or constructing an impossible issuer state in the
test. Neither was done.

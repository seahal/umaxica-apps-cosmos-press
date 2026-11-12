# Press route cleanup after route separation

- Date: 2026-11-09.
- Repository: Cosmos Press; HEAD `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`.
- Tests ran with uncommitted shared-worktree changes, including route separation and owner changes.
  No commit was created. The requested TODO/FIXME markers, MessagePack changes, and documentation
  additions were preserved. This task did not write `.devcontainer/` or `.github/`.

## Failure classification and repairs

- Pre-separation reference: `evidence/2026-11-09-rails-revision-pin-R9P1.md` records 17,164 runs,
  304 failures, and 67 errors. The user-reported immediate post-separation run was 15,169 runs, 787
  failures, and 1,215 errors.
- The first follow-up full run available for this cleanup was 13,373 runs, 98,157 assertions, 74
  failures, and 112 errors. Its sanitized inventory contained 35 exact baseline test-name matches
  (15 failures, 20 errors) and 151 non-matching candidates (59 failures, 92 errors).
- The next full run isolated 8 split-related candidates (3 failures, 5 errors). Removed tests that
  only exercised retired Base/Visa HTTP authorization or client-secret routes; repaired or
  retargeted the retained title, Edit callback, subscriber, mail-interceptor, and route-path guards.
  A RuboCop path autocorrection briefly reintroduced one static path-guard failure; the guard was
  corrected and reverified.
- Final `PARALLEL_WORKERS=1 bin/rails test`: **13,193 runs, 98,457 assertions, 15 failures, 15
  errors, 0 skips**. There are **0 split-related candidates and 0 split-related errors**. Thirteen
  failures and all fifteen errors exactly match the pre-separation inventory. Two further failures
  are the retained Edit cases of two pre-separation RP logout failures; their prior broader test
  names are mapped explicitly in the TSV. They still fail on the existing missing `id_token_hint`
  behavior and were not repaired in production code.
- Final sanitized failure/error inventory, with each test, exception class, and first repository
  location: `/tmp/2026-11-09-press-route-cleanup-final-failures.tsv`. The raw full-suite log was
  deleted after extracting this inventory.

## Retained behavior and scope

- Kept shared Edit RP authentication, local-session, logout, callback, CSRF, and cache-policy checks
  on the retained Press entrypoints. Classified actor support for the retained RP principal without
  changing authentication or authorization order.
- Kept outbound-email suspension coverage using route-independent Com alert/promotional mailers.
  Updated the browser-block subscriber expectation to the retained Info host and adjusted the root
  title contract to allow Edit's product title while still requiring its brand and edition.
- Regenerated the architecture baseline after retired controller removal. The generator completed
  with 88 `Umaxica/NoConcernInclusionHooks` and 2,017 `Umaxica/ExplicitMethodVisibility` baseline
  offenses; `test/tooling/object_placement_test.rb`'s remaining role-suffix failure is an exact
  pre-separation baseline match.

## Verification

- `PARALLEL_WORKERS=1 bin/rails test test/security`: 114 runs, 602 assertions, 0 failures, 0 errors,
  0 skips.
- Focused retained title, route inventory, browser notification, and outbound-email checks: 14 runs,
  1,062 assertions, 0 failures, 0 errors, 0 skips.
- `bin/rubocop`: 4,452 files inspected, no offenses detected.
- `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`: exit 0, 0 errors, 0 security
  warnings.
- `git diff --check`: exit 0.
- Full-suite exit status is 1 only because the listed pre-separation failures and errors remain.
  Database settings and destinations were not changed; no database or volume was created, reset, or
  deleted, and no external service was changed.

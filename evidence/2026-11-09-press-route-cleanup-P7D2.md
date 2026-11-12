# Press route cleanup checkpoint

- Date: 2026-11-09.
- Repository: Cosmos Press; HEAD `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`.
- Results include the shared worktree's uncommitted route separation and other user/owner changes.
  No commit was created. User-identified TODO/FIXME markers, MessagePack dependency changes, and
  documentation additions were preserved. This work did not write `.devcontainer/` or `.github/`.

## Failure classification snapshot

- The route-separation run reported by the user was 15,169 runs, 787 failures, and 1,215 errors.
- The latest completed follow-up full run before the current correction batch was 13,373 runs,
  98,157 assertions, 74 failures, and 112 errors. Its sanitized index has 186 rows.
- Against the pre-separation failure inventory in `/tmp/press-rails-pin-R9P1/test-failures.md`, 35
  rows had an exact test-name match (15 failures, 20 errors). The other 151 rows (59 failures, 92
  errors) were not in that inventory and were treated as split-related candidates pending review.
  Exact-name matching can overcount when a retained test was narrowed or renamed.
- The 151 candidate rows classify as: `Minitest::Assertion` 59, `NoMethodError` 44, `NameError` 29,
  `ActionView::Template::Error` 9, `UnknownError` 4, `RuntimeError` 3, `Timeout::Error` 2, and
  `KeyError` 1.
- Detailed sanitized inventory for that run: `/tmp/2026-11-09-press-route-cleanup-failures.tsv`.

## Work completed in this checkpoint

- Removed or narrowed tests for retired Base/Auth/Visa/Core/Warp/Palm/GUID-owned routes and
  controllers, while retaining Press security contracts and adapting shared checks to Edit or Info.
- Fixed retained Edit rendering and local RP actor classification, and adapted Edit RP session,
  logout, CSRF, health, cache-policy, and browser authentication tests to current Press entrypoints.
- Focused `test/security`: 114 runs, 602 assertions, 0 failures, 0 errors, 0 skips.
- Focused `test/controllers/concerns/browser_rp_authentication_test.rb`: 56 runs, 162 assertions, 0
  failures, 0 errors, 0 skips.
- Full-suite failures/errors eliminated by the current edits have not yet been measured. The last
  observed split-related candidate error count is therefore 92 from the preceding full run; the
  current count is pending the next serialized full-suite run.

## Remaining verification

Update the architecture baseline for retired files, run its contract test, rerun the full security
directory after all edits, then run `PARALLEL_WORKERS=1 bin/rails test` and compare its sanitized
failure/error inventory with the pre-separation baseline. Run full RuboCop, Brakeman, and
`git diff --check` before the final evidence record.

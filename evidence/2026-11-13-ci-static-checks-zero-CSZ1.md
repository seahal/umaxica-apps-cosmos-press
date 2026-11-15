# CI static checks zero — continuation and corrections

Date: 2026-11-13

This record supplements `CSZ0`. It corrects the earlier locale-cleanup and no-Git secret-scan
status; it does not rewrite that first record.

## Revision and worktree

- Full `HEAD`: `4ff0fb165ce782c6f621d7797438e278e114fd1e`.
- The repository already had hundreds of uncommitted changes. At the start of this continuation,
  `git status` reported 522 paths (516 unstaged, 6 untracked, none staged). Results ran against the
  combined worktree and cannot be attributed only to this task.
- After adding this continuation, `git status` reported 523 paths (516 unstaged, 7 untracked, none
  staged).
- No commit or push was made. Database files and encrypted credentials remain unchanged. The
  `.github/workflows/ci.yml` host edit remains untouched.

## Corrections to CSZ0

- Locale bundles were subsequently source-reviewed and pruned. The earlier statement that no
  translations had been removed is superseded. Before this task's cleanup, each locale had 684 leaf
  keys; the current bundles have 338 leaves each, with 349 removed and 3 added per locale.
  `i18n-tasks unused` fell from 1,250 entries (625 per locale) to 556 entries (278 per locale).
- A first `i18n-tasks remove-unused` invocation unexpectedly rewrote the locale bundles. Both
  bundles were restored from `HEAD` before any further edits. The final cleanup used source-reviewed
  key ranges. The Rails `activemodel`, `date`, `datetime`, `helpers`, `number`, `support` and `time`
  translation roots were restored from `HEAD` after auditing Rails' implicit lookup behavior.
- The standard no-Git Gitleaks walk spent over two minutes in generated dependency directories and
  was interrupted. A separate snapshot of 5,168 tracked or non-ignored project files completed. It
  found 109 `generic-api-key` patterns, all in two clean-at-HEAD documents:
  `research/2026-10-22-test-value-audit/duplicates.md` and
  `plans/archive/0003-authentication-handoff-work-logs/zero-agent-message-board.md`. No matched
  values were printed. These remain findings; no allow-list was added.
- `scripts/check-repository-knowledge` now passes after the earlier router-reference updates. The
  prior CSZ0 record's two missing-document routes are no longer current findings.

## Final verification for this continuation

| Check                     | Command and result                                                                                                                                                                                                                                                                   |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| RuboCop                   | `bin/rubocop --fail-level convention` — **1,275 files, 0 offenses**.                                                                                                                                                                                                                 |
| Frozen string directives  | `ruby scripts/check_frozen_string_literal_directives.rb` — **1,348 files passed**.                                                                                                                                                                                                   |
| ERB-Lint                  | `bundle exec erb_lint --lint-all` — **855 files, 16 linters, 0 errors**.                                                                                                                                                                                                             |
| i18n required keys        | `bundle exec i18n-tasks missing` — **0 missing translations**.                                                                                                                                                                                                                       |
| i18n interpolation checks | `bundle exec i18n-tasks check-consistent-interpolations` and `check-reserved-interpolations` — **0 findings**.                                                                                                                                                                       |
| i18n unused inventory     | `bundle exec i18n-tasks unused` — **556 entries / 278 keys per locale** (exit 1 for findings). This is not a CI step in the current workflow. The remaining set includes global attribute/error names and Rails/Active Record implicit lookups; no unused-key suppression was added. |
| Locale parity             | Ruby YAML parse and leaf comparison — **338 matching leaf keys in each locale**.                                                                                                                                                                                                     |
| Focused locale tests      | Four locale test files, including bundle integrity — **9 runs, 60 assertions, 0 failures/errors/skips**.                                                                                                                                                                             |
| Full Rails Minitest       | `RAILS_ENV=test` `bin/rails test`, with process-local database preparation limited to the six retained test databases — **3,735 runs, 42,146 assertions, 0 failures, 0 errors, 0 skips**.                                                                                            |
| Brakeman                  | `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error` — **0 errors, 0 security warnings**.                                                                                                                                                                                |
| Current-tree Gitleaks     | Redacted no-Git snapshot scan — **109 pattern findings** in the two clean-at-HEAD documents above. The history scan in CSZ0 found **247 committed-history findings** (245 `generic-api-key`, 2 `private-key`). Neither scan used an allow-list.                                      |
| Repository knowledge      | `scripts/check-repository-knowledge` — **pass** after this record was added. It reports 0 evidence records because evidence paths are not part of its knowledge-document inventory.                                                                                                  |
| Diff integrity            | `git diff --check` — **pass**.                                                                                                                                                                                                                                                       |

The Bun format/lint/typecheck aggregate, production Vite build, dependency audits and actionlint
results from CSZ0 remain applicable; this continuation changed no JavaScript, dependency, workflow
or ERB files.

## Remaining blockers and scope

- `RAILS_ENV=test bundle exec database_consistency` still reports **24 Publishing `content_digest`
  null-validation findings**. The accepted C10 contract preserves create-only length/format
  validation and rejection of later null updates. Changing that contract needs an owner decision; no
  schema or validation was weakened.
- The 109 current-tree and 247 history Gitleaks pattern findings remain. This task did not rewrite
  shared Git history or alter the clean-at-HEAD documents containing those matches.
- The 556 unused locale entries remain outside the current CI `i18n-tasks missing` step. The scanner
  does not resolve every Rails/Active Record or dynamic lookup; no blanket deletion or suppression
  was applied.
- Existing workflow environment-name findings and Herb comparison are recorded in CSZ0; the
  read-only host workflow edit was not changed.
- No migration, schema edit, credential edit, database reset, CI edit, commit or push occurred.

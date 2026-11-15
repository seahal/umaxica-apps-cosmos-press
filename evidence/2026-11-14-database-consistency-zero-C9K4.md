# Database Consistency Zero: content digest validation

## Revision and scope

- Work order: `plans/2026-11-14-database-consistency-zero-work-order.md`.
- Full `HEAD`: `4ff0fb165ce782c6f621d7797438e278e114fd1e`.
- The worktree had 532 modified/untracked status entries before this task. The shared
  `PublishingEncryptedContent` concern was already modified; its existing configure refactor was
  preserved and made explicit in this touched concern. No unrelated paths were reset or staged.
  Tests ran against this dirty worktree. Before adding this evidence, it had 533 status entries (0
  staged, 524 unstaged, 9 untracked).
- No commit or push was made. No migration, schema dump, Rails configuration, credentials file,
  checker configuration, suppression, exclusion, or allow-list was changed. Final status and diff
  searches found no changes under `config/credentials/` or `db/`.

## Finding inventory and cause

Before the fix, the required command exited 1 with 24 `NullConstraintChecker` findings. Each
identified `content_digest`, a PostgreSQL `NOT NULL` column, whose model validators were limited to
`on: :create`; length and format validators do not prove requiredness to this checker.

The 24 finding identities were:

- `Publishing::Docs::App::EntryRevision#content_digest` and
  `Publishing::Docs::App::EntryVersion#content_digest`
- `Publishing::Docs::Com::EntryRevision#content_digest` and
  `Publishing::Docs::Com::EntryVersion#content_digest`
- `Publishing::Docs::Org::EntryRevision#content_digest` and
  `Publishing::Docs::Org::EntryVersion#content_digest`
- `Publishing::Help::App::EntryRevision#content_digest` and
  `Publishing::Help::App::EntryVersion#content_digest`
- `Publishing::Help::Com::EntryRevision#content_digest` and
  `Publishing::Help::Com::EntryVersion#content_digest`
- `Publishing::Help::Org::EntryRevision#content_digest` and
  `Publishing::Help::Org::EntryVersion#content_digest`
- `Publishing::Info::App::EntryRevision#content_digest` and
  `Publishing::Info::App::EntryVersion#content_digest`
- `Publishing::Info::Com::EntryRevision#content_digest` and
  `Publishing::Info::Com::EntryVersion#content_digest`
- `Publishing::Info::Org::EntryRevision#content_digest` and
  `Publishing::Info::Org::EntryVersion#content_digest`
- `Publishing::News::App::EntryRevision#content_digest` and
  `Publishing::News::App::EntryVersion#content_digest`
- `Publishing::News::Com::EntryRevision#content_digest` and
  `Publishing::News::Com::EntryVersion#content_digest`
- `Publishing::News::Org::EntryRevision#content_digest` and
  `Publishing::News::Org::EntryVersion#content_digest`

The shape is already enforced in PostgreSQL on all 24 tables by `varchar(64) NOT NULL` and a CHECK
requiring exactly 64 lowercase hexadecimal characters. No schema change was needed or made.

## Contract decision and implementation

The digest is computed from canonical revision content when application workflows create a revision;
revision workflows create a new row rather than editing an existing revision. A promoted revision is
immutable under `publishing_promoted_revision_guard`. Versions are immutable through their Active
Record update guard and existing PostgreSQL protection. The database does not freeze an unpromoted
draft revision, so this change does not introduce a new global immutability rule or prevent a valid
64-character lowercase digest update while a revision remains unpromoted. It validates digest shape
on every model validation context and retains existing promoted/version update refusal.

`PublishingEncryptedContent.configure` now declares unconditional presence, exact-length and
lowercase-hex validations. The touched concern uses explicit `model_class` Rails DSL calls rather
than relying on the pre-existing `class_eval` in its uncommitted configure refactor. All twelve
cells continue to configure revision and version records through the shared encrypted-content
concern.

The shared contract test now checks both `NullConstraintChecker` and `ColumnPresenceChecker` for all
24 revision/version models, verifies the twelve-cell source wiring, and covers invalid creation and
update attempts. PostgreSQL constraints and immutability behavior remain independently exercised.
Malformed digest updates now fail model validation before SQL; a valid changed digest still raises
`ActiveRecord::ReadOnlyRecord` for versions and PostgreSQL `PG::RestrictViolation` for promoted
revisions. Direct SQL invalid inserts remain rejected by the existing PostgreSQL constraints.

## TDD and verification

The first Red run after adding the checker and update contract assertions was **26 runs, 2,951
assertions, 13 failures, 0 errors, 0 skips**. It showed the create-scoped validator was still
considered weak by `ColumnPresenceChecker` and invalid update values still reached the old
persistence failure path.

A temporary create-only presence declaration reduced `NullConstraintChecker` to zero but produced 24
`ColumnPresenceChecker` failures because `on:` is a weak option there. The implementation was
changed to unconditional presence and shape validators, without modifying the checker or database
schema.

After the fix, the focused digest contract test passed with **26 runs, 3,333 assertions, 0 failures,
0 errors, 0 skips**. The final related suite passed with **76 runs, 5,155 assertions, 0 failures, 0
errors, 0 skips**. The full Rails suite passed with **3,737 runs, 42,323 assertions, 0 failures, 0
errors, 0 skips**.

| Check                                                                        | Result                                                                              |
| ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Before `RAILS_ENV=test RUBY_DEBUG_ENABLE=0 bundle exec database_consistency` | Exit 1; 24 `NullConstraintChecker` findings listed above.                           |
| Intermediate create-only presence experiment                                 | Exit 1; 0 `NullConstraintChecker` findings and 24 `ColumnPresenceChecker` findings. |
| Final `RAILS_ENV=test RUBY_DEBUG_ENABLE=0 bundle exec database_consistency`  | Exit 0; 0 failure findings across enabled checkers.                                 |
| `bin/rails zeitwerk:check`                                                   | Exit 0.                                                                             |
| `bin/rubocop`                                                                | Exit 0; 1,275 files inspected, no offenses.                                         |
| `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`             | Exit 0; 0 errors and no warnings.                                                   |
| Related PostgreSQL Minitest files                                            | Exit 0; 76 runs, 5,155 assertions, no failures/errors/skips.                        |
| Full PostgreSQL Minitest suite                                               | Exit 0; 3,737 runs, 42,323 assertions, no failures/errors/skips.                    |
| `git diff --check HEAD --`                                                   | Exit 0; no output.                                                                  |

The first targeted test invocation was stopped by the existing `POSTGRESQL_TEST_PREPARE_DATABASES`
startup guard because its configured list includes unverified retired targets. As the work order
allows, Minitest was then run with `env -u POSTGRESQL_TEST_PREPARE_DATABASES`; no environment file
was edited and no environment values are included in this record. The actual test database and
PostgreSQL constraints were used.

No lifecycle or deletion rule changed, so no lifecycle diagram or checklist update was required. The
dated October finding ledger and earlier checker-deferment records remain historical snapshots; this
evidence records the later work-order disposition and actual result. No production, shared, or
external database was touched.

# KEEP database improvements and verification

Date: 2026-11-12. Repository: Cosmos Press. Branch: `feature`. HEAD:
`ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`.

Substantial uncommitted changes affected all results: the initial observation had 426 modified,
3,715 deleted and 58 untracked paths. This is evidence for the combined current worktree, not a
clean HEAD or a claim that every existing difference belongs to this task. Existing work was
preserved. No commit, remote write, CI change, checker configuration/disablement, Solid Queue
change, production operation or shared-database reset was performed.

The four-repository request remains the scope; it was not narrowed to Press. Only Press's current
checkout is available. Other repositories' GitHub copies were inspected read-only and are older than
the split. Full inventory, source commits and uncertainty are in
[inventory](../specs/keep-database-consistency/inventory.md); acceptance stays implementing in
[spec](../specs/keep-database-consistency/spec.md), with
[findings and remaining contracts](../specs/keep-database-consistency/findings.md).

## Environment and ownership

Observed Ruby 4.0.9, Rails 8.2.0.alpha, PostgreSQL 18.6 and vendored database_consistency 3.0.16.
The repository's `.ruby-version` names 4.0.7; no runtime/dependency configuration was changed.
`bundle check` succeeded. The configured test PostgreSQL service `primary:5432` was reachable;
Rails' database safety verification identified only test-prefixed targets on the documented host.

Press has 26 writer families: KEEP `primary`, `storage`, `chronicle`, `publishing`, `rp_edit_org`;
twenty PENDING; Solid Queue EXCLUDED. Replicas are listed separately in the inventory. Role
transfers are not proof of physical retirement. No PENDING/TRANSFER source was edited or rebuilt.
Normal test preparation inspected all configured migration statuses; only intentional KEEP
migrations were applied. No broad database drop task was used.

## Changes and actual TDD observations

| Unit                             | Red observation                                                                                                                            | Green / contract                                                                                                                                                                                                                                                         |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Edit callback digest             | Initial focused run: 2 tests, 6 assertions, 1 failure; duplicate model validation returned true                                            | Model uniqueness added; consumed digests remain reserved; database UNIQUE remains. Final callback coverage is part of the unified pass.                                                                                                                                  |
| Media dimensions                 | 4 tests, 19 assertions, 3 failures: model, `insert_all!` and `update_all` admitted half-known pairs                                        | Both NULL or both positive bounded integers. Four regression tests protect actual CHECK identity, original-row preservation and range boundaries.                                                                                                                        |
| Media placement                  | 12 tests, 12 assertions, 12 failures: nullable-path duplicate insertion succeeded                                                          | All 24 revision/version usage indexes retain the five-column tuple and use NULLS NOT DISTINCT. Direct insertion/update collisions and immutable snapshots are tested.                                                                                                    |
| Publishing integer capacity      | Clean Red: 36 tests, 240 assertions, 24 failures, no errors                                                                                | Before final strict-error assertions: 36 tests, 1,752 assertions, no failures/errors/skips. Final 36-test coverage also checks RecordInvalid rendering. All twelve families exercise schema_version and media positions, valid maxima/promotion and direct SQL overflow. |
| Blazer required values and links | 4 tests, 6 assertions, 3 failures: NULLs, orphans and parent deletion were admitted                                                        | 4 tests, 23 assertions passed after five NOT NULL columns and three NO ACTION FKs. Optional creators and query names remain valid.                                                                                                                                       |
| Blazer nonblank required text    | 5 tests, 26 assertions, 1 failure: blank text was persisted                                                                                | 5 tests, 135 assertions passed. Two CHECKs reject the framework's Unicode-whitespace-only partition while preserving accepted text bytes, including full-width surrounding spaces and zero-width-space behavior. Test SQL uses bound values.                             |
| Vocabulary rollback              | Disposable migration rollback failed with PG::RestrictViolation because the down method tried DELETE against permanent-retirement triggers | Revised down raises IrreversibleMigration explicitly; the runner exited 0 with seeded rows unchanged. No trigger was removed.                                                                                                                                            |

Chronicle's additional migration validates nineteen existing audit/outbox FKs. Its retained
[separate record](2026-11-12-press-chronicle-consistency-C9F2.md) contains the test-first Red. This
session independently ran the migration regression: 1 test, 9 assertions, zero failures, errors or
skips, including existing-row upgrade, SQL orphan refusal, exact rollback metadata and
reapplication. An early independent rebuild exposed a Chronicle schema mismatch; the final rebuild
and live-dump comparisons passed after the validation migration. These are combined-tree results,
not an assertion of exclusive authorship of previously appearing files.

Important new tests:

- `test/models/rp_edit_org_callback_state_consistency_test.rb`
- `test/models/publishing/media_dimensions_contract_test.rb`
- `test/models/publishing/media_placement_uniqueness_test.rb`
- `test/models/publishing/integer_storage_bounds_test.rb`
- `test/models/operator_tool_database_constraints_test.rb`
- `test/migrations/chronicle_rebuild_integrity_test.rb`

Five new migrations own the dimensions CHECK, 24 media indexes, Chronicle validation, Blazer
requiredness/FKs and Blazer nonblank CHECKs. Three schema dumps were generated through Rails:
`db/publishing_structure.sql`, `db/chronicle_structure.sql`, `db/structure.sql`. No dump was edited
by hand. Three shared publishing concerns align 48 concrete models' integer input ranges; MediaFile
and Edit callback are the other concrete model changes. Current architecture and the browser RP
checklist were updated.

The historical vocabulary migration changes only its down refusal, plus equivalent array formatting.
Its up operation is unchanged. Rewriting a recorded migration does not automatically reapply it in
an already-migrated environment. No existing migration history was deleted. An empty generated
migration was briefly recorded by automatic test preparation before its file was renamed; its empty
receipt was removed from the local test publishing schema metadata. The final dump and fresh rebuild
contain only the real eight publishing migrations.

## Final tests and lint

Executed as one standard Rails invocation:

```bash
PARALLEL_WORKERS=1 bin/rails test \
  test/models/publishing \
  test/models/rp_edit_org_callback_state_consistency_test.rb \
  test/models/rp_local_schema_contract_test.rb \
  test/models/operator_tool_database_constraints_test.rb \
  test/controllers/edit/org/publishing \
  test/controllers/edit/org/api/v0/publishing/entries_controller_test.rb \
  test/integration/content_surface_boundary_test.rb \
  test/integration/default_no_store_publishing_content_test.rb \
  test/integration/wua6_publishing_context_parity_test.rb \
  test/migrations/chronicle_rebuild_integrity_test.rb
```

Result: **666 tests, 17,263 assertions, 0 failures, 0 errors, 0 skips**, exit 0. This includes
retained API/management integration and all new tests; it is not the full repository suite. The
earlier 635-test publishing/RP coverage run also passed all assertions, as did a separate 25-test
integration run. Counts from overlapping runs are not added together.

Scoped `bin/rubocop` on all seventeen changed Ruby source/test/migration files: no offenses, exit 0.
Scoped `git diff --check` also passed. No lint configuration or baseline was changed.

`PARALLEL_WORKERS=1 COVERAGE=true bin/rails test test/models/publishing test/models/rp_edit_org_callback_state_consistency_test.rb test/models/rp_local_schema_contract_test.rb`
ran 635 tests / 16,751 assertions with no failures/errors/skips, but exited **2** at the unchanged
whole-application coverage gate: line 53.98%, branch 2.01%, method 6.74%. This focused run does not
cover unrelated application code; the coverage gate is not reported as passed. All executable lines
of the two changed concrete models and three changed publishing concerns were covered. MediaFile had
23/23 lines, 6/6 branches and 4/4 methods; Edit callback had 16/16 lines and its one method covered.
Migration execution/rollback is separately observed, not claimed as complete SimpleCov migration
coverage.

## Reconstruction, upgrade and rollback

Rails runner scripts outside the repository used `DatabaseTasks.create`, each configuration's own
migration context and temporary connection, and `DatabaseTasks.drop` for isolated `test_press_*`
databases. Existing names were checked before the complete-rebuild harness created its disposable
targets. Every created target was cleaned up. Queue and PENDING stores were not reconstructed. Raw
schema-object DDL was not introduced outside migrations.

| Writer      | Migrations from empty | Application tables | Fresh structure equals live test DB | Live dump equals worktree |
| ----------- | --------------------: | -----------------: | ----------------------------------- | ------------------------- |
| primary     |                     4 |                  6 | yes                                 | yes                       |
| storage     |                     1 |                  0 | yes                                 | yes                       |
| chronicle   |                    31 |                 46 | yes                                 | yes                       |
| rp_edit_org |                     8 |                  6 | yes                                 | yes                       |
| publishing  |                     8 |                157 | yes                                 | yes                       |

Comparisons used the repository's `SchemaDriftVerification.normalize` and `dump_matches?`, not a
handwritten whitespace-stripping comparison. These are writer migration/schema observations;
replication operation and separate test replica freshness were not tested.

Publishing's new migrations passed down/up rehearsal: original dimensions expression and ordinary
NULL-distinct index metadata restored, then all 24 stronger indexes restored; vocabulary seed rows
were preserved. No temporary replacement index remained in the live catalog.

Primary's two new migrations passed down/up/reapplication with a retained valid query. Separate
missing-value, orphan-reference and blank-value preflights were exercised in the disposable prior
schema. Each refused migration left the offending record present; only disposable fixture rows were
removed before retrying. These are existing-schema upgrade tests, distinct from the empty rebuilds
above. Existing retained test databases were not dropped.

Catalog audit across all five KEEP writers found no application table without a primary key,
nullable boolean or FK column type mismatch. All constraints were validated in fresh rebuilt stores.
Publishing retained 228 application triggers, and its live catalog had 24 NULLS NOT DISTINCT media
indexes with zero temporary replacement indexes.

Required `RAILS_ENV=test bin/rails db:verify_no_schema_drift` **failed**: it checks git dump
differences as well as generated structure equality and includes PENDING databases. Reported paths
were app_setting, app_zenith, avatar, occurrence, op_base_app, op_base_org, org_setting, org_zenith
and the intentional chronicle, publishing and primary dump changes. The direct KEEP comparisons
above passed. No commit or out-of-scope dump rewrite was made to turn the gate green.

## DatabaseConsistency and unfinished acceptance

Both baseline and final used exactly `RAILS_ENV=test bundle exec database_consistency`, with no
configuration file. Both exited **1**. The final output began
`No configuration files were provided`. The checker implementation was inspected for coverage
limitations and left unchanged.

| Scope                  | Baseline grouped reports | Final grouped reports | Final underlying offenses |
| ---------------------- | -----------------------: | --------------------: | ------------------------: |
| KEEP                   |                      435 |                   434 |                       434 |
| PENDING                |                      284 |                   284 |                       300 |
| Solid Queue (excluded) |                        0 |                     0 |                         0 |
| Total                  |                      719 |                   718 |                       734 |

Final KEEP: publishing 432 (192 UniqueIndex, 168 MissingDependentDestroy, 60 NullConstraint, 12
ColumnPresence); chronicle 2 UniqueIndex; primary/storage/Edit 0 observed reports. The removed
report is Edit callback uniqueness. The more serious media, Blazer and historical FK validation
defects were outside what this standard run detected; Blazer is development-loaded.

The 60 publishing null reports concern custom JSON validation, exact digest validation and
trigger-derived snapshots. Twelve presence reports concern create-only checks and legitimate
projected updates. Restrictive FK reports are not permission for CASCADE. Taxonomy's preserved
database duplicate exception contract conflicts with adding ordinary uniqueness preflights just to
satisfy UniqueIndexChecker. These are concrete limitations, not a declaration that every remaining
report is a false positive.

**Full acceptance remains open.** Remaining work includes individual uniqueness/deletion contract
review, dependency-owned nullable status semantics, complete concurrency/lifecycle/security
coverage, whole-application coverage, PENDING ownership decisions and the other three repositories'
current implementations. There is no claim of zero KEEP findings or of completed all-repository
remediation. Production data prerequisites and lock/size impact remain unverified. The new
constraint migrations fail on conflicting stored data rather than repairing or deleting it.

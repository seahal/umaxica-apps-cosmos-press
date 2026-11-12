# Press retained database consistency and Chronicle validation

Date: 2026-11-12. HEAD: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`, branch `feature`. Substantial
existing uncommitted split changes affected every observation. The owner narrowed this task to
Press; other repositories were not modified. No commits, CI changes, checker configuration, Solid
Queue changes or production operations were performed.

## Scope and concurrent work

See [all 26 writers](../docs/architecture/press-database-retention.md). Five are KEEP, twenty
PENDING, queue EXCLUDED. No current physical database has sufficient evidence for RETIRE or
TRANSFER. The referenced `plans/immutable-wibbling-jellyfish.md` is absent in this checkout.

An independent process ran similarly named checks and changed callback and publishing files while
this task was active. The task's agents confirmed they did not make those changes. The user was
asked to identify the concurrent writer; no answer had arrived at this record's creation. To avoid
collisions, overlapping implementation was held. In particular, callback uniqueness and locale
changes and the two new publishing migrations are concurrent work, not claimed as this agent's
implementation. Their presence affects final combined-worktree results.

## Changes owned by this task

- `db/chronicle_migrate/20261112112802_validate_chronicle_retained_foreign_keys.rb`: validate
  eighteen audit event/level foreign keys and the Chronicle outbox reference, preserving deletion
  actions. Rollback atomically restores each original NOT VALID key without deleting rows.
- `db/chronicle_structure.sql`: generated from an independently rebuilt PostgreSQL database;
  nineteen validation-state changes and one migration-history addition. No hand-edited dump.
- `test/migrations/chronicle_rebuild_integrity_test.rb`: rebuild, existing-row upgrade, orphan
  refusal, exact rollback definitions and reapplication in its own random `test_press_*` database.
- `test/models/rp_edit_org_callback_state_consistency_test.rb`: duplicate/independent state,
  consumed-state reservation and validation-bypassing database uniqueness regression coverage.
- Current retention documentation and implementing specification.

Tested migration SHA-256: `a7b721fc3d092132c6a4c89aa6fd1e280617ab3edc9c8d8a051742eec6199edd`.
Migration test SHA-256: `cc0b39d25a38798f8c0712761328cd45298d12ce43d288394b0cfab2186f2ed9`.
Generated dump SHA-256: `ada0e040664a8f91765dca1ef6e6d9c0c10c39e7b619cc71109ecde94217df97`.

## Red and Green

`RAILS_ENV=test bundle exec ruby test/migrations/chronicle_rebuild_integrity_test.rb` first failed:
1 test, 2 assertions, 1 failure, listing nineteen unvalidated foreign keys after clean migration.
The existing test database had already validated them; rebuilding exposed the historical gap.

After implementation and round-trip assertions: 1 test, 9 assertions, zero failures/errors/skips.
The pre-change history is migrated to `20261103183220`, an outbox row is inserted, the new migration
runs, a direct SQL orphan update raises `PG::ForeignKeyViolation`, rollback reproduces the original
foreign-key definitions and validation metadata, and reapplication leaves no unvalidated key.
Temporary databases were created and removed through Rails database tasks; schema objects were
created/changed only by owning migrations. Existing migration history was not rewritten.

The callback test's first run failed while constructing `RecordInvalid` because a concurrent change
lacked the state-digest attribute translation. It later passed with the concurrent model/locales: 1
test, 9 assertions, no failures/errors/skips. This is not claimed as this task's independent
Red-to-Green implementation of callback uniqueness.

## Regression, lint and coverage

`PARALLEL_WORKERS=1 bin/rails test test/models/chronicle_test.rb test/models/chronicle_outbox_entry_test.rb test/models/client_chronicle_test.rb test/models/operator_chronicle_test.rb`:
39 tests, 96 assertions, no failures/errors/skips.

`PARALLEL_WORKERS=1 bin/rails test test/models/rp_edit_org_callback_state_consistency_test.rb`: 1
test, 9 assertions, no failures/errors/skips.

Scoped RuboCop on the new migration and both new tests: 3 files, no offenses. The Chronicle dump
diff also passed `git diff --check`.

Final standard-runner integration:
`PARALLEL_WORKERS=1 bin/rails test test/migrations/chronicle_rebuild_integrity_test.rb test/models/chronicle_outbox_entry_test.rb`:
3 tests, 12 assertions, zero failures/errors/skips. This also verifies that the isolated migration
test restores the normal Base connection for neighboring tests. Both new Ruby files passed
`ruby -c`.

Ruby Coverage over the isolated migration round trip: 15/15 executable source lines and 2/2 methods.
MigrationContext reloads the class between directions, resetting per-file counters; the diagnostic
sampler collected coverage at returns and merged by source location across up/down/up. A
final-load-only measurement was 8/15 lines and 3/6 runtime method definitions and does not represent
the whole round trip. This is scoped migration coverage, not suite-wide or application authorization
coverage. No coverage configuration was changed.

## Reconstruction and schema agreement

All five KEEP databases were independently recreated through their configured migration paths in
random `test_press_root_rebuild_*` databases on the configured local test PostgreSQL host. Each
database was dropped after its inspection and dump. Queue and PENDING databases were not rebuilt.

| Database    | Tables including Rails metadata | Migrations | Unvalidated constraints |
| ----------- | ------------------------------: | ---------: | ----------------------: |
| publishing  |                             159 |          8 |                       0 |
| chronicle   |                              48 |         31 |                       0 |
| rp_edit_org |                               8 |          8 |                       0 |
| primary     |                               8 |          2 |                       0 |
| storage     |                               2 |          1 |                       0 |

All five fresh dumps matched their worktree reference using the repository's
`SchemaDriftVerification.normalize`. All five live test-database dumps also matched their references
using `SchemaDriftVerification.dump_matches?`. The initial four-database catalog scan found no
nullable boolean columns or tables without primary keys in publishing, chronicle, Edit or primary.
These observations do not prove every domain invariant or index is correct.

The required `RAILS_ENV=test bin/rails db:verify_no_schema_drift` command **failed**. It includes
intentional uncommitted dump differences and pre-existing differences in PENDING databases:
app_setting, app_zenith, avatar, occurrence, op_base_app, op_base_org, org_setting, org_zenith, plus
chronicle and publishing. The command checks git cleanliness as well as semantic agreement; no
commit was made to suppress that result. Do not report this gate as passed.

## DatabaseConsistency

Both baseline and final commands were exactly `RAILS_ENV=test bundle exec database_consistency`,
without configuration files. Both exited 1. Findings were classified by an eagerly loaded Active
Record model-to-effective-connection inventory; no model names were unresolved.

| Scope       | Baseline grouped report lines | Final grouped report lines | Final underlying offenses |
| ----------- | ----------------------------: | -------------------------: | ------------------------: |
| KEEP        |                           435 |                        434 |                       434 |
| PENDING     |                           284 |                        284 |                       300 |
| Solid Queue |                             0 |                          0 |                         0 |
| Total       |                           719 |                        718 |                       734 |

Final KEEP lines: UniqueIndexChecker 194, ColumnPresenceChecker 12, NullConstraintChecker 60,
MissingDependentDestroyChecker 168. The one-line reduction is the concurrent Edit callback
uniqueness change. Chronicle's nineteen incomplete validations were outside these checker findings.
Queue's zero observed report lines do not constitute a Solid Queue audit; it remains excluded.

## Unfinished work and limits

Full retained-database consistency acceptance is **not achieved**. Remaining findings require
individual fixes or principled checker capability work. In particular, the custom JSON-object
validator, trigger-derived position snapshot and create-only projected-publication behavior are not
fully modeled by the checker. Restrictive foreign-key warnings are not permission for CASCADE. Do
not describe all remaining findings as proven false positives.

Publishing's ordinary-duplicate exception handling is coupled to operation-specific index names;
changes need coordinated tests and operation updates. The audit also found media-position and
schema-version integer upper-bound gaps and obsolete raw table names in an immutability test. Those
items were not changed while overlapping writer scope remained unresolved.

PENDING database ownership, retained audit-uniqueness warnings, broader model/constraint audit,
all-family lifecycle/concurrency verification and suite-wide coverage remain open. External writer
changes were not independently reviewed in full. No production/shared database reset occurred.

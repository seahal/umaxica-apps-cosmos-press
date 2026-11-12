# Publishing restoration reference indexes

- Commit: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`.
- The worktree contained substantial existing uncommitted changes. Results include the current kept
  Publishing models, restoration navigation associations, tests, and the new migration; they are not
  results for the commit alone.
- Scope: 24 nonunique Btree indexes on `restored_from_revision_id` and `restored_from_version_id` in
  the twelve Publishing revision tables. No model, column, constraint, queue, or CI changes belong
  to this unit.

## TDD and source verification

Commands used the explicit six retained test database names in `POSTGRESQL_TEST_PREPARE_DATABASES`
and `PARALLEL_WORKERS=1`.

`bin/rails test test/models/publishing/restoration_reference_index_test.rb` first produced **24
runs, 72 assertions, 24 failures, zero errors/skips**. The public restoration navigation returned
the expected records, but PostgreSQL `EXPLAIN` showed sequential scans for every reference even with
`SET LOCAL enable_seqscan = off`.

The migration was generated with
`RAILS_ENV=test bin/rails generate migration IndexPublishingRestorationReferences --database publishing`,
then assigned version `20261112151000`. It uses `disable_ddl_transaction!`, 24 explicit concurrent
additions, and 24 concurrent removals in reverse order. Concrete family methods keep the
declarations in the owning migration without suppressing lint rules.

After the coordinated test Publishing migration, the same test produced **24 runs, 144 assertions,
zero failures/errors/skips**. Each case verifies the public history lookup and an actual PostgreSQL
index condition using the expected index. This verifies index eligibility for the reference lookup;
it is not a production workload benchmark.

RuboCop inspected the migration and test with zero offenses. Ruby syntax and scoped
`git diff --check` passed.

## Isolated migration rehearsal

Command: `RAILS_ENV=test bin/rails runner /tmp/press-restoration-index-rehearsal.rb`, with the same
explicit test database list and one worker.

The script required Rails test mode, the configured `test_publishing_db` source on `primary`, and a
fresh random database name matching `test_press_restoration_indexes_[0-9a-f]{12}`. Native Rails
`DatabaseTasks` created and dropped only that isolated database. Native Publishing migration
contexts performed all schema changes; no test cloner or ad hoc schema DDL was used.

The database was rebuilt through the preceding Publishing migration. Native model writes seeded
twelve entries, 36 revisions, and twelve versions, including real references to both restoration
sources. Before applying the index migration, the script captured exact JSON row hashes for all 158
public data tables, all constraint definitions/validation attributes, and the complete existing
index catalog. The native `schema_migrations` rows were excluded from data comparison because
migration tracking necessarily changes.

All three stages passed:

| Stage    | Restoration indexes | Verification                                                                                                       |
| -------- | ------------------: | ------------------------------------------------------------------------------------------------------------------ |
| Up       |                  24 | Each index has the expected single column, nonunique Btree method, no predicate, and PostgreSQL valid/ready flags. |
| Down     |                   0 | The exact original index catalog is restored.                                                                      |
| Up again |                  24 | All index definitions and valid/ready flags are restored.                                                          |

At every stage, all 158 data-table hashes, all constraints, and all unrelated index definitions
remained unchanged. The isolated database was dropped successfully in guarded cleanup.

## Limits

The rehearsal verifies a completed migration's rollback and reapplication. An interrupted concurrent
build can leave an invalid index and requires explicit inspection and cleanup before retrying;
conditional existence checks do not conceal that state. Empty rebuild and drift verification for the
complete retained database set are separate coordinated checks.

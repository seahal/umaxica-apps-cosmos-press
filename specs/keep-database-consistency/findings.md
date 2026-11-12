# Retained database findings and implementation disposition

Status: implementing. Scope and acceptance remain in [spec.md](spec.md); physical ownership is in
[inventory.md](inventory.md). This record does not close the earlier pre-split remediation spec.

## Order and dependencies

1. Establish physical ownership before editing a database. Other repositories' current checkouts are
   unavailable; the public copies do not establish their current development state.
2. Fix concrete database integrity holes in confirmed Press KEEP stores: paired media dimensions,
   nullable media placement uniqueness, and unvalidated Chronicle references. Preserve immutable
   snapshots, retirement triggers and restrictive deletion policies.
3. Align model input acceptance with existing PostgreSQL contracts: Edit state uniqueness and
   publishing integer bounds. Keep race protection in the database.
4. Make vocabulary rollback explicitly refuse deletion of authoritative taxonomy history.
5. Rebuild each KEEP store from its own migration paths, rehearse new migration rollback and
   reapplication, compare live/fresh/dumped structures, then run regression and integration tests.
6. Continue individual remaining checker findings only after mapping their actual domain and error
   contracts. Do not replace a correct constraint with checker-oriented behavior.

## Concrete contracts

| Unit                                 | Before                                                             | After                                                                       | Authority and compatibility                                                                                                            |
| ------------------------------------ | ------------------------------------------------------------------ | --------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Edit callback state                  | Database UNIQUE, no model duplicate preflight                      | Model preflight plus unchanged database UNIQUE                              | Fixed Edit realm/client and existing digest authority; consumed digests remain reserved.                                               |
| Media dimensions                     | CHECK admits a single NULL through SQL UNKNOWN                     | Both NULL, or both NOT NULL and positive; matching bounded model validation | Uploaded image metadata; no invented dimensions or automatic data repair. Existing invalid rows abort migration.                       |
| Media placement, all 24 owner tables | UNIQUE treats NULL paths as distinct                               | Same five-column tuple, `NULLS NOT DISTINCT`                                | Owner, role, paths and position define the slot. Either path alone remains valid; immutable version guards remain.                     |
| Chronicle references                 | Nineteen foreign keys created NOT VALID                            | Validate existing constraints and historical rows                           | Event/level catalogs and nullable outbox link; deletion actions and rows unchanged.                                                    |
| Publishing integer input             | Some models accept values beyond PostgreSQL integer capacity       | Model accepts only the existing column range                                | `schema_version` starts at one; media position starts at zero. No database type or external enum change.                               |
| Vocabulary seed rollback             | Attempts DELETE despite permanent-retirement trigger               | Explicit `IrreversibleMigration`, rows retained                             | Seeded vocabulary identities can own historical assignments; retirement uses archiving.                                                |
| Blazer primary persistence           | Five required columns nullable; three local parent links lack FKs  | Five NOT NULL columns and three NO ACTION FKs                               | Bundled Blazer model contracts; optional creator and Query name remain optional. Invalid existing rows abort migration without repair. |
| Blazer required text                 | Direct SQL permits empty and Unicode-whitespace-only required text | Two CHECK constraints match Active Support's Unicode whitespace set         | Statement and dashboard name preserve nonblank text exactly; zero-width space follows the framework's accepted partition.              |

The new publishing indexes are replaced atomically: build the stronger replacement first, then
remove and rename within the transaction. A duplicate aborts without deleting records or leaving an
enforcement gap. Builds block writes and require a production table-size and maintenance-window
assessment before deployment. The dimensions CHECK similarly takes a lock and validation scan. The
Blazer migration preflights missing values and orphan references, then adds constraints in one
transaction. Its validation scans and NOT NULL changes also require lock review before production.
Only the local test database was upgraded; production and shared instances were not touched.

New migrations upgrade already-applied schemas. The historical vocabulary migration changes only its
`down` refusal; its `up` remains unchanged. Editing historical migration text does not reapply it to
an environment that has already recorded the version. Generated empty migration receipts created
during local generation must not survive in final dumps.

## Remaining checker findings

The baseline Press KEEP scope has 435 grouped reports. After Edit model alignment it has 434:

| Database   | Checker                        | Reports | Disposition                                                                                                                          |
| ---------- | ------------------------------ | ------: | ------------------------------------------------------------------------------------------------------------------------------------ |
| publishing | UniqueIndexChecker             |     192 | Review each preflight/error contract; native UNIQUE remains enforced.                                                                |
| publishing | MissingDependentDestroyChecker |     168 | Reverse model deletion declarations are incomplete; database RESTRICT is retained. No CASCADE is justified by the warning.           |
| publishing | NullConstraintChecker          |      60 | Static limitations: 24 JSON-object body validators, 24 exact digest format/length validators, 12 trigger-derived position snapshots. |
| publishing | ColumnPresenceChecker          |      12 | Create-only `effective_from` validation preserves existing projected-record updates.                                                 |
| chronicle  | UniqueIndexChecker             |       2 | Audit idempotency/error contracts require individual review.                                                                         |

There are no observed KEEP reports on primary, storage or Edit after the change. This does not
establish complete scanner coverage of framework-owned models or a full security audit. Blazer is
required only in development, so the test-environment checker did not reveal its missing
constraints. The bundled model source and direct PostgreSQL tests established those contracts.
Flipper's reserved synchronization gate deliberately has no feature row; a gate-to-feature FK would
violate its dependency contract and was not added.

The vendored checker is version 3.0.16. Its implementation was inspected, not disabled or changed:
`NullConstraintChecker` recognizes only selected declarative validators, not arbitrary custom JSON
validation or authoritative BEFORE INSERT derivation. `ColumnPresenceChecker` treats `on:` as a weak
option and does not model projected updates. `MissingDependentDestroyChecker` recognizes reverse
dependent declarations or cascade/nullify actions; it does not accept a restrictive FK by itself.
`UniqueIndexChecker` requests an exact matching model uniqueness validator even when the database
intentionally owns duplicate refusal.

These limits explain specific reports, but do not prove every remaining report false. In particular,
D1 in the [earlier decisions](../database-consistency-remediation/decisions.md) explicitly preserves
taxonomy `RecordNotUnique` behavior. Adding a normal uniqueness validator changes it to
`RecordInvalid`; removing the index or changing the checker to skip the requirement is not an
acceptable route to zero. The current `CreateEntryOperation` also maps a specifically named slug
UNIQUE violation to its domain refusal. Model preflight changes require coordinated caller and
failure-contract design rather than bulk validator insertion.

## Open acceptance and limits

- All remaining findings stay visible; zero-warning acceptance is open.
- Other repositories' current branches, dirty worktrees, physical instances and tests are not
  available here. Public GitHub snapshots were used read-only.
- Twenty Press writer families remain PENDING; their findings are reported separately and their
  schemas are not changed. Queue is EXCLUDED even when the normal Rails test preparation reads its
  migration status.
- Full application coverage and all-family concurrency/lifecycle/security coverage are not
  established by the focused regression suite.
- Blazer's dependency-owned nullable status fields still require a separate lifecycle contract
  review; their framework semantics are preserved.
- The repository-wide drift task also checks uncommitted dump differences and PENDING stores; its
  failure must remain separate from successful direct KEEP dump comparisons.
- Evidence must identify actual Red/Green runs, scoped migration rehearsals, coverage failures and
  final report counts. Neither this document nor a test name is a verification result.

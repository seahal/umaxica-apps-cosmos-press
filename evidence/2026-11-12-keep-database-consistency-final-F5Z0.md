# KEEP database consistency: final local verification

HEAD: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`; branch `feature`. Extensive uncommitted split work
existed before either task. No reset, stash, revert, commit or remote write was performed. This
report supersedes earlier **intermediate counts**, not their historical observations.

## A. Database disposition and repository limits

Only Cosmos Press has a current local checkout. Access/Governance/Sphere public references were
inspected read-only; their available snapshots cannot establish current development branches,
uncommitted work or provisioned instances. No unavailable destination implementation is claimed
improved.

| Repository | Observed source                                                                | Classification and implementation boundary                                                                                                                                                                                                                                                           |
| ---------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Press      | Current local `feature`, HEAD above, dirty worktree prioritized                | KEEP: `primary`, `storage`, `chronicle`, `publishing`, `rp_edit_org`; EXCLUDED: `queue` (Solid Queue). Writers and all configured replicas are inventoried.                                                                                                                                          |
| Access     | Public `f7c208cd6dd325e47a72caf78673afcec5a52612` (2026-09-08), pre-split tree | All current physical instances PENDING because no current checkout/instance is available; Solid Queue EXCLUDED. Publishing responsibility TRANSFER to confirmed Press KEEP. OP responsibility belongs to Access; old `app_ticket`/`org_ticket` names are not proof of current `op_base_*` instances. |
| Governance | Public `f24fb7b49f0059ee66e932eb8a07bceac5b89cee` (2026-10-09), pre-split tree | All current physical instances PENDING because no current checkout/instance is available; Solid Queue EXCLUDED. Publishing responsibility TRANSFER to Press. Accounts, credentials, profiles, avatars, preferences and notifications belong to Governance under the later owner instruction.         |
| Sphere     | Public `6425b6305ea6dac852b8bf93d07d26b201ae43e6` (2026-10-09)                 | The observed tree has no database/model/migration/schema. No current local instance is established; future ownership is not classified as a provisioned KEEP database.                                                                                                                               |

Both Access and Governance public snapshots contain exactly these twenty writer keys: `publishing`,
`platform`, `storage`, `chronicle`, `avatar`, `app_ticket`, `org_ticket`, `com_ticket`,
`app_zenith`, `org_zenith`, `com_zenith`, `app_setting`, `org_setting`, `com_setting`, `app_signal`,
`org_signal`, `com_signal`, `search`, `occurrence`, `queue`. Every key except `platform`/`queue` has
its corresponding `_replica`. For current physical-instance editing all non-queue keys remain
PENDING; the role/transfer distinctions above and the original
[inventory](../../specs/keep-database-consistency/inventory.md) preserve the observed historical
responsibilities. No physical RETIRE decision is inferred from a deleted connection, renamed
migration directory or empty reserved schema.

The later Press retirement instruction explicitly removed its twenty non-owned writer families,
their replicas and consumers. Their complete per-family ownership, intentional remaining grep hits
and documentation handoff are in
[the retirement record](2026-11-12-remove-non-press-databases-P6R2.md). No source physical database
was dropped; no destination deployment was inferred. Old `publisher` is not current `publishing`;
old principal histories are not additional surviving principal connections.

The handoff plan names eight program repositories, including mock OIDC and edge components, but no
additional current Rails database-owner checkout was found. `plans/immutable-wibbling-jellyfish.md`
is absent; no missing plan content was invented. Superseded architecture documents were treated as
historical and are listed for Claude, not rewritten by the retirement task.

## B. Implemented database/model contracts

| KEEP database / unit                               | Concrete change                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Publishing media files                             | Paired dimensions CHECK rejects half-NULL pairs and nonpositive values, preserving both-NULL or positive bounded dimensions.                                                                                                                                                                                                                                                                                                                                  |
| Publishing revision/version media usage, 24 tables | Existing five-column UNIQUE placement tuple strengthened with PostgreSQL NULLS NOT DISTINCT; legitimate nullable path fields remain.                                                                                                                                                                                                                                                                                                                          |
| Publishing model graph                             | Reverse navigation for 168 retained association findings; uniqueness validation aligned for 192 uniqueness-related contracts, including legitimate partial scopes. Ordinary duplicates use RecordInvalid as owner-approved; validation-bypass/native races retain database uniqueness. Narrow CreateEntry/PromoteRevision handling preserves public failure semantics.                                                                                        |
| Publishing typed values                            | JSON body nil/type validation, publication datetime validation and bounded schema/media integer validation preserve PostgreSQL capacities and Infinity/date boundary semantics.                                                                                                                                                                                                                                                                               |
| Ordered taxonomy snapshots, 12 tables/models       | `position_snapshot` is STORED GENERATED from `position`; redundant model assignment removed. Ordinary model creation explicitly rejects user-supplied snapshots (including equal values and nil) using the documented statically named `position_snapshot_came_from_user?` interface. All prior snapshot fields, immutable/deferred triggers, NOT NULL and position CHECK remain. The full shared snapshot function changes only its obsolete position write. |
| Publishing restoration provenance                  | 24 ordinary nonunique Btree indexes on `restored_from_revision_id`/`restored_from_version_id`, built/dropped concurrently; deletion/foreign-key behavior remains restrictive.                                                                                                                                                                                                                                                                                 |
| Chronicle                                          | 19 previously unvalidated foreign keys validated without deleting history.                                                                                                                                                                                                                                                                                                                                                                                    |
| ClientChronicle                                    | Nullable UUID uniqueness on creation; malformed supplied UUIDs cannot silently become nil through ordinary model validation. No new UUID-version restriction.                                                                                                                                                                                                                                                                                                 |
| OperatorChronicle                                  | Event 18 retains original JSON authority; two STORED TEXT projections support the same-name partial UNIQUE index. CHECK requires an object, both existing string keys and Unicode-nonblank values, using IS TRUE. Opaque strings including `0`/`-1` remain valid. Other events remain independent. Invalid legacy histories stop before DDL.                                                                                                                  |
| Primary / Blazer                                   | Five NOT NULL columns, three NO ACTION foreign keys and two Unicode-nonblank CHECKs on required text. Optional creator/name semantics remain.                                                                                                                                                                                                                                                                                                                 |
| Edit RP                                            | Callback state digest uniqueness before persistence, retaining the native UNIQUE and single-use replay boundary.                                                                                                                                                                                                                                                                                                                                              |
| Storage                                            | Reserved empty application schema survives; no content or foreign-domain tables added.                                                                                                                                                                                                                                                                                                                                                                        |

Eight intentional new migrations across the two phases of the original consistency work:

- `db/publishing_migrate/20261112010000_enforce_paired_publishing_media_dimensions.rb`
- `db/publishing_migrate/20261112112556_enforce_publishing_media_placement_uniqueness.rb`
- `db/chronicle_migrate/20261112112802_validate_chronicle_retained_foreign_keys.rb`
- `db/migrate/20261112114503_enforce_blazer_persistence_contracts.rb`
- `db/migrate/20261112115320_enforce_blazer_required_text.rb`
- `db/publishing_migrate/20261112150000_generate_publishing_taxonomy_positions.rb`
- `db/publishing_migrate/20261112151000_index_publishing_restoration_references.rb`
- `db/chronicle_migrate/20261112152000_enforce_operator_halt_correlation.rb`

The seed rollback that conflicts with permanent-retirement triggers now explicitly raises
IrreversibleMigration rather than pretending deletion succeeds. Historical applied migration edits
do not automatically re-run in an existing installation; this limit remains explicit. No
invariant-bearing trigger was discarded to satisfy a checker. The owner-approved SQL exception is
limited to the existing Publishing snapshot function replacement and DROP EXPRESSION rollback; other
new schema changes use native migration DSL. Stored generation rewrites/locks tables and production
deployment needs a separate size/lock assessment; production was not migrated.

The generic checker correction recognizes only exact built-in positive static length validators,
without running predicates or introducing model/connection names or exclusions. Runtime package is
`database_consistency 3.0.16` from the existing nested fork. Its exact patch, fork HEAD and
four-test proof are exported in [L64P](2026-11-12-database-consistency-length-proof-L64P.md); the
ignored nested dependency diff must accompany the parent changes. No `.database_consistency.yml`,
disabled checker, model exclusion or connection exclusion was added.

The retained auth boundary now passes the current verified request payload explicitly to domain
policies, requires a principal, and grants no domain capability for missing/malformed/unknown
context. Anonymous request admission remains a separate unchanged predicate set. The JWT verifier
already rejected unknown contexts; it was not relaxed, and no exploitable unknown-JWT bypass is
claimed. See [C73A](2026-11-12-request-policy-claims-C73A.md).

## C. TDD and direct PostgreSQL evidence

Earlier callback, dimensions, media placement, capacity, Blazer and irreversible-reference tests
have their actual Red/Green counts in [K7P4](2026-11-12-keep-database-improvements-K7P4.md).
Additional bounded units:

| Unit                                 | Observed Red                                                                                                                                                                         | Observed Green                                                                                                                                                                                                                                                                                                                                                                                       |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Generated positions                  | 12 tests, 12 meaningful failures: a supplied forged snapshot was accepted/overwritten                                                                                                | 12 tests / 108 assertions; omission derives positions 0 and 2147483647, supplied values refuse, immutable updates/completeness preserved.                                                                                                                                                                                                                                                            |
| Dependent raw-SQL contracts          | Full coverage found 24 failures because fixtures explicitly wrote the newly generated field, masking their intended original error                                                   | Only generated field omitted; all original NOT NULL, negative CHECK, overflow, truncation and immutable assertions retained: 132 tests / 4176 assertions pass.                                                                                                                                                                                                                                       |
| Ordinary model generated-field input | Native SQL was protected but all twelve ordinary model saves silently omitted supplied `999`: 24 tests / 120 assertions, 12 failures                                                 | 24 tests / 684 assertions pass. Nine explicit input partitions per cell (forged/equal/nil/empty/invalid string/array/hash/false/float) raise RecordInvalid; omitted values derive normally. Twelve static validation declarations call one pure private concern method; no new inclusion hook or position copying. Related position/capacity/promotion regression: 144 tests / 4220 assertions pass. |
| Restoration indexes                  | 24 tests / 72 assertions, 24 failures: disabled sequential scans instead of Index Cond                                                                                               | 24 tests / 144 assertions pass, checking actual PostgreSQL plans and inverse results.                                                                                                                                                                                                                                                                                                                |
| Chronicle uniqueness/context         | 10 tests / 38 assertions, 4 semantic failures and 2 missing-projection errors; separate UUID run 6 tests / 26 assertions, 2 failures                                                 | Combined two contract suites and existing halted suite: 18 tests / 193 assertions pass. Includes ordinary duplicates, native duplicate/bad-context bypass, optional UUID and malformed supplied UUID partitions.                                                                                                                                                                                     |
| Request policy claims                | Ambient-context/nil/unknown policy failures; missing controller wire caused valid HTTP requests to return 403; nil principal with a normal claim incorrectly granted an owner result | 102 tests / 541 assertions plus 20 tests / 98 strengthened assertions pass. Parallel independent policy instances and interleaved real HTTP clients are distinct proofs.                                                                                                                                                                                                                             |
| Length inference                     | Conservative checker cases versus actual framework nil rejection                                                                                                                     | 4 tests / 45 assertions pass, including a permissive custom subclass that remains reported.                                                                                                                                                                                                                                                                                                          |

Standalone isolated databases were created only under exact fresh guarded test prefixes and dropped
with native DatabaseTasks after verification:

- Snapshot UP/DOWN/UP: all 12 tables, 24 valid boundary rows, every original field and timestamp
  unchanged; generation s → ordinary → s, NOT NULL/CHECK unchanged, original function restored on
  down. A mismatch cannot naturally be inserted through the legacy immutable/snapshot guards, so no
  trigger-disable/ad-hoc-DDL corruption was used; the mismatch rejection branch is not claimed
  experimentally exercised.
- Restoration index UP/DOWN/UP: twelve entries, 36 revisions and twelve versions; all 158 public
  tables except schema_migrations, all constraints and unrelated index definitions unchanged. All 24
  new indexes valid/ready; down returns the exact baseline catalog.
  [I24R](2026-11-12-publishing-restoration-indexes-I24R.md).
- Chronicle UP/DOWN and invalid legacy upgrade: historical row/id/JSON preserved, original
  index/check/columns restored exactly; a legacy JSON-null correlation stops the upgrade before DDL
  and preserves both rows plus version metadata. No data auto-repair or deletion.

Final normal suite command (actual necessary environment):

```sh
POSTGRESQL_TEST_PREPARE_DATABASES=test_primary_db,test_publishing_db,test_rp_edit_org_db,test_chronicle_db,test_queue_db,test_storage_db PARALLEL_WORKERS=1 bin/rails test
```

**3628 runs, 42011 assertions, zero failures/errors/skips, exit 0.** This is the non-system suite.
Live external Access and the other repositories' latest deployments were not exercised; signed
external-provider fixtures and actual local PostgreSQL/RP flows were exercised.

Full coverage execution also ran **3628 tests with zero failures/errors/skips**, but SimpleCov exits
**2**: line **91.70%** (12219/13324), branch **60.44%** (1169/1934), method **86.18%** (1816/2107),
below configured 98%/93%/97% global floors. Floors/configuration were not weakened. Pre-change
whole-suite coverage was not measured, so this failure is not labelled pre-existing. The prior
complete coverage capture measured representative affected-file line coverage: ClientChronicle 100%,
OperatorChronicle 95.08%, request context 100%, ApplicationPolicy 100%, PublishingEntryPolicy 100%,
BrowserRpAuthentication 74.39%; the final aggregate above additionally includes the generated-input
guard. These Ruby measures do not quantify SQL-trigger/CHECK coverage; the PostgreSQL proofs above
are separate.

## D. Final commands, residual issues and limits

| Check                                                            | Actual result                                                                                                                                                                                                                                               |
| ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `RAILS_ENV=test bundle exec database_consistency`                | Exit 0, **KEEP warnings 0**. Solid Queue EXCLUDED; **0 queue findings observed**. Console only notes no configuration was provided.                                                                                                                         |
| `bin/rubocop`                                                    | Exit 0, 1255 files, zero offenses.                                                                                                                                                                                                                          |
| `bundle exec erb_lint --lint-all`                                | Exit 0, 855 files, zero errors.                                                                                                                                                                                                                             |
| `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error` | Exit 0, zero errors/security warnings.                                                                                                                                                                                                                      |
| Development `db:prepare`                                         | Exit 0; connected database identities verified as development_primary/storage/chronicle/rp_edit_org/publishing on local primary.                                                                                                                            |
| Test `db:prepare`                                                | Exit 0 with the exact six-writer preparation list.                                                                                                                                                                                                          |
| `bun run check`                                                  | Exit 1 only at generated OpenAPI `git diff --exit-code` versus dirty HEAD; format, lint, typecheck, OpenAPI lint pass. Final bundle regeneration is byte-idempotent; no source OpenAPI contract edited for this task.                                       |
| `db:verify_no_schema_drift`                                      | Exit 1 because the task additionally requires SQL dumps clean versus HEAD. After explicit native regeneration, independent live-versus-working-dump comparison is **true for all ten configured connections**. The failed exit is reported, not suppressed. |
| Full coverage gate                                               | Exit 2 at unchanged global floors, as quantified above.                                                                                                                                                                                                     |

Schema dumping is explicitly disabled after migration in this repository's environments. The final
working dumps were generated with
`RAILS_ENV=test bin/rails db:schema:dump:publishing db:schema:dump:chronicle`, then inspected. Two
dedicated local test replica copies were behind their writers; their existing KEEP migrations were
applied through native migration contexts after exact test database/host and non-streaming-primary
assertions. No actual streaming standby, production, external or shared database was directly
migrated. Reading comparison then matched publishing, publishing_replica, rp_edit_org,
rp_edit_org_replica, queue, storage, storage_replica, chronicle, chronicle_replica and primary
against their working definitions.

Other residuals:

- `.github` is mounted read-only. The retirement's necessary workflow DB-list cleanup remains
  un-applied; `/tmp/press-ci-db-binding.patch` is prepared. Only `config/ci.rb` foreign DB-list
  entries were edited under that task's explicit scope; no CI redesign, hook or pipeline work was
  performed during consistency resumption.
- Governance data remains unavailable to retained Press paths until its authoritative interface
  exists. Responses/errors are explicit; no preferences, identity, author permission or avatar
  defaults were fabricated. Public Publishing reads and Edit relying-party tests pass.
- Direct malformed UUID SQL is rejected; ordinary model input is validated; native UNIQUE protects
  duplicates. An AR validation-bypass API can cast malformed UUID text to permitted SQL NULL before
  PostgreSQL sees it, which the database cannot distinguish from explicit optional NULL. No stronger
  original-input guarantee is claimed.
- Destination/current Access/Governance/Sphere implementation work remains unavailable, not silently
  complete. Source physical DB disposal is unasserted and no retirement DB was dropped.
- The nested checker patch must be packaged with the existing fork. No upstream/remote publish was
  authorized or performed.
- Concurrent index builds are non-transactional. An interrupted partial build needs catalog
  inspection and a scoped repair plan before retry; the rehearsal proves fully applied up/down/up,
  not simulated production interruption.
- Source/schema deployment and rollback must be coordinated; no backward-compatible or zero-downtime
  rollout is claimed.
- Full historic rollback was not claimed: permanent vocabulary reference data deliberately refuses
  irreversible deletion. Rehearsals cover the three new reversible units, plus empty-history full up
  execution.

## E. Final local determination

| KEEP writer | Empty DB migrations | Rebuild versus live schema |
| ----------- | ------------------: | -------------------------- |
| primary     |                   4 | match                      |
| storage     |                   1 | match                      |
| chronicle   |                  32 | match                      |
| rp_edit_org |                   8 | match                      |
| publishing  |                  10 | match                      |

All five fresh rebuilds succeeded and their scratch databases were dropped. All five catalog audits
report: missing primary keys **0**, nullable booleans **0**, mismatched FK key type OIDs **0**,
unvalidated constraints **0**, invalid/unready indexes **0**, exact duplicate index signatures
**0**. Solid Queue migration/dump fingerprints remain unchanged. Working schema files and actual
databases now agree; Git-clean gates still correctly expose the uncommitted work.

The local Press KEEP checker target is achieved with full non-system tests green. Global coverage,
the read-only workflow edit and unavailable current checkouts remain explicit unfinished items; this
is not a claim of four-repository production completion. Documentation/ADR/checklist/diagram
ownership handoff stays with Claude as requested.

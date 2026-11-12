# Database Ownership Inventory

Observation date: 2026-11-12. This is the implementation-scope inventory for the
[KEEP database consistency change](spec.md), not a database deletion or transfer procedure.

## Source precedence and limitations

The sole available local repository is `/home/global/workspace`, Cosmos Press, branch `feature`,
HEAD `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`. The initial worktree contained 426 modified, 3,715
deleted and 58 untracked paths from existing work. Local code and accepted split decisions take
precedence over GitHub. These counts describe the initial observation, not a clean baseline or the
final task diff.

Read-only GitHub references:

| Repository | Observed main HEAD                                                                                                                                 | Commit date | Available contents                               |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | ------------------------------------------------ |
| Access     | [f7c208cd6dd325e47a72caf78673afcec5a52612](https://github.com/seahal/umaxica-apps-cosmos-access/tree/f7c208cd6dd325e47a72caf78673afcec5a52612)     | 2026-09-08  | Pre-split Rails application, 9,474 paths         |
| Governance | [f24fb7b49f0059ee66e932eb8a07bceac5b89cee](https://github.com/seahal/umaxica-apps-cosmos-governance/tree/f24fb7b49f0059ee66e932eb8a07bceac5b89cee) | 2026-10-09  | Same pre-split database definitions, 9,474 paths |
| Sphere     | [6425b6305ea6dac852b8bf93d07d26b201ae43e6](https://github.com/seahal/umaxica-apps-cosmos-sphere/tree/6425b6305ea6dac852b8bf93d07d26b201ae43e6)     | 2026-10-09  | Only `.gitignore`, `LICENSE` and `README.md`     |

All three recursive GitHub tree responses were complete (`truncated: false`). These references
establish only the public snapshot, not the latest development branch, uncommitted work, deployed
instances or live data. The other repositories have no current local checkout available for
implementation or runtime verification. No remote changes are in scope.

The current program has eight repositories according to `plans/2026-11-12-handoff.md`: the four
Cosmos applications, `umaxica-apps-mock-oidc`, `umaxica-apps-edge`, `umaxica-apps-edge-jump` and
`umaxica-apps-edge-away`. `umaxica-apps-edge-core` is explicitly outside the program. No additional
current Rails database owner was established by this survey.

## Classification semantics

KEEP means confirmed surviving ownership. RETIRE means confirmed physical retirement; no current
configured instance below is assigned RETIRE solely from missing callers. TRANSFER describes a
confirmed source and destination responsibility; it does not prove that a destination physical
instance has been provisioned or authorize dropping a source. Where that distinction remains
unsettled, the physical instance is PENDING and excluded from edits. EXCLUDED means Solid Queue.

Replica keys are listed explicitly. In local development they normally point to their writer's
physical database on another host; test replicas use distinct physical database names. This is a
connection/instance distinction, not an additional domain ownership decision. Both members of a
listed pair have the same edit classification.

## Current local Press configuration

Source: [database.yml](../../config/database.yml), current abstract records, migrations and dumps.
All database names below refer to the configured writer; corresponding test names use the `test_`
prefix. No production placement or deployment state is inferred.

| Writer connection | Replica connection    | Development physical name    | Classification | Basis / unresolved boundary                                                                                                               |
| ----------------- | --------------------- | ---------------------------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `publishing`      | `publishing_replica`  | `development_publishing_db`  | KEEP           | Press is sole content authority; `PublishingRecord` owns the family.                                                                      |
| `primary`         | none                  | `development_primary_db`     | KEEP           | Own default/operator-tool database; `ApplicationRecord` explicitly owns primary.                                                          |
| `storage`         | `storage_replica`     | `development_storage_db`     | KEEP           | Own reserved storage instance; common-database ADR and migration README preserve it independently of publishing.                          |
| `chronicle`       | `chronicle_replica`   | `development_chronicle_db`   | KEEP           | Own full audit schema, including unused families, under common-database ADR.                                                              |
| `rp_edit_org`     | `rp_edit_org_replica` | `development_rp_edit_org_db` | KEEP           | Press Edit's independent RP state; `RpEditOrgRecord`.                                                                                     |
| `app_zenith`      | `app_zenith_replica`  | `development_app_zenith_db`  | PENDING        | Historical authentication/authorization mixture; physical-instance disposition is not settled.                                            |
| `org_zenith`      | `org_zenith_replica`  | `development_org_zenith_db`  | PENDING        | Same mixed ownership; principal history is consolidated here.                                                                             |
| `app_setting`     | `app_setting_replica` | `development_app_setting_db` | PENDING        | Preference placement remains open.                                                                                                        |
| `org_setting`     | `org_setting_replica` | `development_org_setting_db` | PENDING        | Preference placement remains open.                                                                                                        |
| `com_setting`     | `com_setting_replica` | `development_com_setting_db` | PENDING        | Preference placement remains open; anonymous COM is not a deletion decision.                                                              |
| `app_signal`      | `app_signal_replica`  | `development_app_signal_db`  | PENDING        | Split placement and surviving Press requirement unconfirmed.                                                                              |
| `org_signal`      | `org_signal_replica`  | `development_org_signal_db`  | PENDING        | Split placement and surviving Press requirement unconfirmed.                                                                              |
| `search`          | `search_replica`      | `development_search_db`      | PENDING        | Configured reserved empty application schema; repository adoption is open.                                                                |
| `occurrence`      | `occurrence_replica`  | `development_occurrence_db`  | PENDING        | Governance is the main intended user; other repositories' adoption and data handling remain open.                                         |
| `avatar`          | `avatar_replica`      | `development_avatar_db`      | PENDING        | Canonical responsibility transfers to Governance; current Press physical-instance disposition and destination implementation unconfirmed. |
| `op_base_app`     | `op_base_app_replica` | `development_op_base_app_db` | PENDING        | Authentication responsibility transfers to Access; no confirmed current destination instance in this environment.                         |
| `op_base_org`     | `op_base_org_replica` | `development_op_base_org_db` | PENDING        | Authentication responsibility transfers to Access; same physical-instance limitation.                                                     |
| `rp_base_app`     | `rp_base_app_replica` | `development_rp_base_app_db` | PENDING        | Base RP responsibility transfers to Governance; physical-instance disposition unconfirmed.                                                |
| `rp_base_org`     | `rp_base_org_replica` | `development_rp_base_org_db` | PENDING        | Base RP responsibility transfers to Governance; physical-instance disposition unconfirmed.                                                |
| `rp_tech_org`     | `rp_tech_org_replica` | `development_rp_tech_org_db` | PENDING        | Tech RP responsibility transfers to Governance; physical-instance disposition unconfirmed.                                                |
| `rp_core_app`     | `rp_core_app_replica` | `development_rp_core_app_db` | PENDING        | Core RP responsibility transfers to Sphere; current local destination implementation unavailable.                                         |
| `rp_core_org`     | `rp_core_org_replica` | `development_rp_core_org_db` | PENDING        | Core RP responsibility transfers to Sphere; same limitation.                                                                              |
| `rp_warp_app`     | `rp_warp_app_replica` | `development_rp_warp_app_db` | PENDING        | Warp RP responsibility transfers to Sphere; same limitation.                                                                              |
| `rp_warp_org`     | `rp_warp_org_replica` | `development_rp_warp_org_db` | PENDING        | Warp RP responsibility transfers to Sphere; same limitation.                                                                              |
| `rp_palm_app`     | `rp_palm_app_replica` | `development_rp_palm_app_db` | PENDING        | Palm RP responsibility transfers to Sphere; same limitation.                                                                              |
| `queue`           | none                  | `development_queue_db`       | EXCLUDED       | Solid Queue; all related artifacts and configuration are outside this change.                                                             |

There are 26 configured writer keys: five KEEP, twenty PENDING and one EXCLUDED. No physical
instance is declared RETIRE or TRANSFER without a confirmed instance-level disposition. Confirmed
responsibility transfers above remain useful for finding the destination without editing sources.

Principal is a semantic inheritance seam, not another physical database. Current
`AppPrincipalRecord` inherits `AppZenithRecord`, and `OrgPrincipalRecord` inherits
`OrgZenithRecord`; the zenith bases own `connects_to`. Matching principal and zenith migration
directories are applied to the same database. There is no configured `*_principal`, `publisher`,
`com_zenith`, `op_base_com` or `com_signal` key in this checkout. Old `publisher` does not establish
current `publishing` ownership. `cache` and `cable` reservations are not configured databases.

`db/storages_migrate` and `db/searches_migrate` each document their empty application schema and
extension migration. Empty storage survives by explicit ownership; empty search remains pending.
Neither is permission to repurpose a database. `db/audit_schema.rb` and the `.orig` dump are
artifacts, not evidence of an additional configured database.

## Access and Governance public snapshots

Sources:
[Access database.yml](https://github.com/seahal/umaxica-apps-cosmos-access/blob/f7c208cd6dd325e47a72caf78673afcec5a52612/config/database.yml)
and
[Governance database.yml](https://github.com/seahal/umaxica-apps-cosmos-governance/blob/f24fb7b49f0059ee66e932eb8a07bceac5b89cee/config/database.yml).
Both snapshots configure the following twenty writers, with the same migration histories and
physical-name pattern `development_<writer>_db` / `test_<writer>_db`. Their abstract records use the
listed connections; none is a current split deployment inventory.

| Writer        | Replica               | Access classification                                                    | Governance classification                                                 | Current ownership limit                                                                            |
| ------------- | --------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `publishing`  | `publishing_replica`  | TRANSFER responsibility to Press; source physical instance PENDING       | TRANSFER responsibility to Press; source physical instance PENDING        | Confirmed destination domain is Press KEEP `publishing`; no source deletion or copy is authorized. |
| `platform`    | none                  | PENDING physical instance; KEEP default/tooling role                     | PENDING physical instance; KEEP default/tooling role                      | Common ADR requires `primary`; old `platform` is not proof of a physical rename or drop.           |
| `storage`     | `storage_replica`     | KEEP role / reference schema                                             | KEEP role / reference schema                                              | Each repository owns an independent storage instance; latest local implementation unavailable.     |
| `chronicle`   | `chronicle_replica`   | KEEP role / reference schema                                             | KEEP role / reference schema                                              | Independent full audit schema in every repository.                                                 |
| `avatar`      | `avatar_replica`      | TRANSFER canonical responsibility to Governance; physical source PENDING | KEEP canonical responsibility / reference schema                          | Latest Governance instance and migration path unavailable locally.                                 |
| `app_ticket`  | `app_ticket_replica`  | KEEP authentication responsibility; old physical key PENDING             | TRANSFER authentication responsibility to Access; physical source PENDING | Current local naming uses `op_base_app`; old key is not a current instance map.                    |
| `org_ticket`  | `org_ticket_replica`  | KEEP authentication responsibility; old physical key PENDING             | TRANSFER authentication responsibility to Access; physical source PENDING | Same distinction for `op_base_org`.                                                                |
| `com_ticket`  | `com_ticket_replica`  | PENDING                                                                  | PENDING                                                                   | Old anonymous-surface authentication schema; current survival not established.                     |
| `app_zenith`  | `app_zenith_replica`  | PENDING                                                                  | PENDING                                                                   | Authentication and authorization families require physical ownership resolution.                   |
| `org_zenith`  | `org_zenith_replica`  | PENDING                                                                  | PENDING                                                                   | Same mixed ownership.                                                                              |
| `com_zenith`  | `com_zenith_replica`  | PENDING                                                                  | PENDING                                                                   | Old COM principal/projection implementation is not a current survival decision.                    |
| `app_setting` | `app_setting_replica` | PENDING                                                                  | PENDING                                                                   | Preference placement open.                                                                         |
| `org_setting` | `org_setting_replica` | PENDING                                                                  | PENDING                                                                   | Preference placement open.                                                                         |
| `com_setting` | `com_setting_replica` | PENDING                                                                  | PENDING                                                                   | Preference placement open.                                                                         |
| `app_signal`  | `app_signal_replica`  | PENDING                                                                  | PENDING                                                                   | Split signal ownership not established.                                                            |
| `org_signal`  | `org_signal_replica`  | PENDING                                                                  | PENDING                                                                   | Split signal ownership not established.                                                            |
| `com_signal`  | `com_signal_replica`  | PENDING                                                                  | PENDING                                                                   | Current COM signal survival not established.                                                       |
| `search`      | `search_replica`      | PENDING                                                                  | PENDING                                                                   | Reserved role; per-repository adoption open.                                                       |
| `occurrence`  | `occurrence_replica`  | PENDING                                                                  | PENDING physical instance; Governance is intended main user               | Adoption and existing-data handling remain open; no current instance verified.                     |
| `queue`       | none                  | EXCLUDED                                                                 | EXCLUDED                                                                  | Solid Queue.                                                                                       |

The shared remote migration counts are: app principal 322, app zenith 32, app settings 8, app
signals 3, app tickets 62; org principal 223, org zenith 36, org settings 7, org signals 3, org
tickets 43; com principal 63, com zenith 29, com settings 7, com signals 3, com tickets 54; avatars
38, chronicle 19, occurrences 114, platform 1, publishing 4 and queues 5. `search` and `storage`
have configuration and dumps but no Ruby migration in these public trees. Counts are historical
source observations, not migration execution results.

## Sphere public snapshot

No database configuration, model, migration or schema exists in the observed public tree. There are
therefore no configured keys to classify there. The accepted direction requires Sphere's own
`primary`, `storage`, `chronicle` and excluded `queue`, and its own RP state for Core, Warp and
Palm. This is future KEEP responsibility, not evidence of a provisioned database or tested schema.
Business database placement, audit content after Access independence, regional distribution of
Avatar copies and the concrete Warp role remain unresolved.

## Decision reconciliation and missing inputs

- `adr/principal-zenith-physical-consolidation.md` is partially superseded by
  `adr/global-regional-database-ownership.md`. Claims that old principal connections remain
  configured or are regional application stores are stale. Current connection and inheritance
  evidence above controls the observed implementation.
- `docs/architecture/model-database-inventory.md` and
  `docs/architecture/database-authority-placement.md` contain older principal reservation and
  content placement descriptions. Current content authority follows
  `adr/publishing-db-content-authority.md` and its explicit later supersessions, including
  `adr/publishing-twelve-family-encrypted-persistence.md`; old zenith content is not KEEP content
  authority merely because a historical inventory says so.
- `adr/chronicle-audit-db-consolidation.md` consolidates historical activity/behavior naming; the
  current common-database ADR requires independent full Chronicle schemas per repository.
- `adr/surface-database-connection-naming.md` is a naming decision, not physical retirement proof.
  Its old ticket vocabulary must be read with the subsequent OP rename.
- `adr/solid-cache-removal-and-valkey-cache-separation.md` and later common-name reservations do not
  establish an active Solid Cache database. Queue remains excluded regardless of warnings.
- `plans/immutable-wibbling-jellyfish.md`, requested as a starting reference, is absent from the
  current checkout. No missing plan content or acceptance is reconstructed from its name.
- `docs/backlog/2026-10-26-database-consistency-findings.md` records an older 690-finding scan. That
  is historical backlog, not this task's baseline or a current KEEP count.
- `plans/2026-11-12-handoff.md` calls for a DB/model report before removal. This inventory does not
  perform removal; the current user request separately authorizes isolated development/test KEEP
  reconstruction. Shared, external and production databases remain untouched.

No database retirement, migration execution, PostgreSQL constraint test, checker run or coverage
result is asserted by this inventory. Those results require separate session evidence.

# Press database retention and consistency scope

Current decision inventory, 2026-11-12. This distinguishes retained physical databases from
connection renames, table retirement, migration history and empty reservations. It does not
authorize dropping any database.

| Classification | Writer connections                                                           | Current authority                                                                                                                                                                                                                                     |
| -------------- | ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| KEEP           | publishing                                                                   | [Publishing authority](../../adr/publishing-db-content-authority.md), [Press ownership](../../adr/cosmos-base-surface-decomposition.md)                                                                                                               |
| KEEP           | rp_edit_org                                                                  | Edit is the retained local RP; `RpRequestAuthenticator` registers this cell and `RpEditOrgRecord` owns its local records.                                                                                                                             |
| KEEP           | primary, chronicle, storage                                                  | [Common connections](../../adr/cosmos-common-database-connections.md), decisions 1 and 3. Each repository owns an independent instance. Chronicle retains unused families too. Storage is currently an empty reservation with an extension migration. |
| PENDING        | app_zenith, org_zenith, op_base_app, op_base_org, rp_base_app, rp_base_org   | [Route ownership](../../specs/cosmos-press-route-ownership/spec.md) defers physical removal and retains legacy paths until Edit independence. Domain allocation is not a physical database retirement decision.                                       |
| PENDING        | rp_core_app, rp_core_org, rp_warp_app, rp_warp_org, rp_palm_app, rp_tech_org | The route ownership spec identifies removal candidates, not an accepted physical removal.                                                                                                                                                             |
| PENDING        | app_setting, org_setting, com_setting, app_signal, org_signal, avatar        | The current split leaves usage, preference placement or remaining dependencies unresolved. Canonical Avatar ownership in Governance alone does not settle the Press database's disposal.                                                              |
| PENDING        | occurrence, search                                                           | Common-connections open questions leave per-repository adoption unresolved. Search is currently an empty reservation.                                                                                                                                 |
| EXCLUDED       | queue                                                                        | Solid Queue is outside this improvement task.                                                                                                                                                                                                         |

There are 26 configured writers: five KEEP, twenty PENDING and one EXCLUDED. There is no confirmed
RETIRE or TRANSFER physical database in this inventory. Matching replicas follow their writer's
classification. Development replicas use the same database names on the replica host; configured
test replica names identify separate test databases.

`app_principals_migrate` and `org_principals_migrate` are history paths applied to zenith databases,
not separate current principal connections. `publisher` is not `publishing`. Historical `activity`,
`behavior`, cache, com zenith and com signal names are not current configured databases. The
November split decisions qualify the older Global/Regional inventory documents.

## Retained audit references

`ValidateChronicleRetainedForeignKeys` completes validation of nineteen existing foreign keys left
NOT VALID by earlier migrations. It preserves columns, targets, constraint names and deletion rules,
including the outbox's SET NULL behavior. Invalid historical references cause migration failure;
this migration performs no data repair or deletion. Validation scans existing rows with PostgreSQL's
validation locks, one statement at a time outside an encompassing DDL transaction.

Rollback atomically recreates each affected key with its previous validation metadata. It retains
enforcement for new writes and preserves rows; rollback requires brief exclusive table locks and
should be planned accordingly. A subsequent migration run validates the same references again.

The migration integration test rebuilds an independent temporary PostgreSQL database, upgrades the
preceding history with an existing outbox row, exercises a direct-SQL orphan refusal and checks the
exact constraint definitions across rollback and reapplication. No existing migration history was
rewritten for this correction.

## Checker interpretation

Run `RAILS_ENV=test bundle exec database_consistency` without suppression configuration. Classify
each finding using its model's effective connection; report grouped lines separately from their
underlying offense counts. A process exit code includes pending databases and is not a retained
database acceptance result.

Publishing includes restrictive foreign keys, immutable snapshots, trigger-derived fields and
existing database-exception contracts. The checker cannot infer arbitrary custom validators or
BEFORE INSERT derivation. Its uniqueness and inverse-association recommendations still require
individual contract review; those findings are not all established false positives. Preserve the
underlying invariants and PostgreSQL tests while resolving them.

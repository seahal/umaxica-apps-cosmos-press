# Press database consistency

Status: implementing

Accepted by the owner's database improvement request on 2026-11-12; scope narrowed to Press in the
same conversation. No commits, external writes, CI changes or Solid Queue changes.

## Purpose and boundaries

Improve retained PostgreSQL contracts and Active Record consistency without weakening
authentication, audit retention, content immutability, ownership or conditional uniqueness. Preserve
the existing uncommitted split work. Public GitHub snapshots are background only.

Retained connections: publishing, primary, chronicle, storage and rp_edit_org. Replicas follow their
writer's ownership. Storage is a retained empty reservation, not evidence of Active Storage tables.
All other configured connections except queue remain pending a physical database ownership/removal
decision. Queue is excluded. Domain transfer does not establish physical database retirement.

## Acceptance

- AC-1: Classify every configured Press database with current decision evidence before editing it.
- AC-2: Reproduce each material implementation defect with a failing behavioral test before fixing
  it; preserve direct PostgreSQL enforcement and existing stronger assertions.
- AC-3: Run database_consistency with no configuration or disabled checkers, separating retained,
  pending and Solid Queue findings. Investigate unsupported valid PostgreSQL constructs rather than
  changing valid contracts to satisfy the checker.
- AC-4: Rebuild retained databases from migrations in isolated disposable databases, distinguish
  this from upgrading an existing schema, and inspect generated dumps and drift.
- AC-5: Record regression, lint and coverage observations and all incomplete acceptance honestly.

## Execution order and unresolved inputs

Inventory and baseline first; then Edit callback state, publishing contracts and audit contracts in
independent units. Each unit uses Red, Green, refactoring, lint, coverage, integration and checker
verification appropriate to its behavior. No shared database is reset. Schema changes require owning
migrations and generated dumps; rewriting history never updates already-applied environments.

Pending: twenty configured connections have no final physical-retention decision. Existing tests
deliberately require database uniqueness exceptions for some publishing taxonomy operations; checker
warnings alone do not authorize replacing those exceptions with validation errors.

## Current execution disposition

The full [retention inventory](../../docs/architecture/press-database-retention.md) covers all 26
writers. A new Chronicle migration and PostgreSQL integration test resolve nineteen previously
unvalidated foreign keys discovered during clean reconstruction. The test covers an existing-row
upgrade, direct-SQL orphan rejection, rollback and reapplication. The generated Chronicle dump
corresponds to that migration.

Another process edited overlapping callback and publishing files during this task. Confirmation of
that writer's scope is pending in the conversation; overlapping implementation is held to avoid
overwriting independent work. The callback regression test passes with the concurrent model and
translation changes, but this task does not claim authorship of those changes or their Red cycle.
Publishing's remaining consistency findings and substantive contract decisions remain open.

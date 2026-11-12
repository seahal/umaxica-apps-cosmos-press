# KEEP Database Consistency

Status: implementing (accepted by the owner in the 2026-11-12 database improvement request).

## Purpose and scope

Improve the surviving PostgreSQL databases of Cosmos Access, Governance, Sphere and Press so that
Active Record contracts, migrations and physical constraints agree. The goal is zero
`database_consistency` findings for KEEP databases without suppressions, together with direct
PostgreSQL verification of invariants the checker cannot establish.

The current editable checkout is Press. Its branch, dirty worktree and current accepted decisions
take precedence over older GitHub copies. The [inventory](inventory.md) records which databases have
confirmed KEEP ownership and which remain withheld. It distinguishes physical instances, connection
names, table ownership, migration histories and empty reserved databases.

Changes may redesign KEEP models, migrations, constraints and indexes. Significant changes follow
Red, Green, Refactor, lint/format, relevant coverage review and integration verification, in bounded
table or model-family units. Business requirements, authentication and authorization invariants,
audit history, lifecycle rules and surface isolation remain requirements.

## Exclusions and authority

- RETIRE and PENDING databases are withheld from implementation. TRANSFER sources are withheld; work
  at a destination requires confirmed surviving ownership and an available implementation.
- Solid Queue is completely excluded, including its database, models, tables, migrations,
  constraints, indexes and configuration. Its findings are counted separately.
- CI/CD, GitHub Actions, local CI configuration and Git hooks are excluded.
- GitHub access is read-only. No remote repository changes or commits are authorized by this spec.
- Production, external and shared databases are not modified or rebuilt. Development/test
  reconstruction is authorized only after confirming the target and KEEP status; isolated disposable
  databases are preferred. Broad commands such as `db:drop:all` are unsuitable.
- Existing unrelated staged, unstaged and untracked changes are preserved. Checker configuration,
  checker disablement, model/connection exclusions and exit-code suppression are prohibited.

The current request authorizes development/test destructive refactoring within those boundaries;
historical work orders do not expand the scope or reopen unrelated cleanup. Physical transfer or
retirement decisions are not implied by the deletion of routes or by this inventory.

## Acceptance

- AC-1: Every configured database in the available checkouts and read-only reference repositories
  has an explicit classification, current source and confidence limit. Unknown ownership remains
  PENDING. Missing current checkouts and unresolved migrations are reported.
- AC-2: Each implemented unit defines its database contract and has meaningful regression tests
  added before the fix, with the observed Red and Green outcomes retained in evidence.
- AC-3: Relevant validation-bypass paths run against actual PostgreSQL. Tests cover applicable NULL,
  uniqueness, foreign-key, deletion, conditional uniqueness, ordering/range boundaries, concurrency
  and lifecycle contracts without weakening existing assertions.
- AC-4: KEEP models and physical schema agree on requiredness, keys, defaults, associations,
  deletion actions, uniqueness and ownership. Cross-database references follow the accepted policy;
  authorized triggers retain their invariants. The audit also examines migration order,
  reversibility, duplicate history and schema drift beyond the checker's capabilities.
- AC-5: KEEP databases can be rebuilt from empty isolated databases by their complete migration
  histories; generated structures and actual databases agree. Existing-schema upgrade verification
  is recorded separately. Rewritten applied migrations are explicitly identified as requiring
  reconstruction or a separate upgrade path.
- AC-6: `RAILS_ENV=test bundle exec database_consistency` runs with the project's actual runtime and
  connections. KEEP findings reach zero without suppression, or remaining findings and exact
  blockers remain open. Checker compatibility defects and true false positives are investigated
  without destroying valid PostgreSQL design.
- AC-7: Proportionate lint, relevant existing tests, integration tests and coverage observations are
  recorded. The final report separates KEEP findings and test counts, excluded Solid Queue findings,
  PENDING/TRANSFER/RETIRE work, rebuild results and unverified risks.

## Execution and verification

Inventory and dependencies precede edits. Start with confirmed Press KEEP families, reproduce each
concrete inconsistency and fix one coherent unit at a time. Independent KEEP work continues while
other databases await a decision. Re-run the checker after each unit and inspect the final diff
against ownership and exclusions.

Initial implementation units concern the Edit RP state contract and publishing media metadata and
positions. Their status is implementation in progress, not completed acceptance. Test counts,
commands, coverage, migration results and finding counts belong in revision-scoped `evidence/`
records and the final report; this document does not assert that any verification passed.

Use the repository's documented Rails runtime, PostgreSQL and verification commands. Run lint only
through existing commands; changing CI is outside scope. Record full HEAD and the effect of the
dirty worktree in evidence. A blocked boot or unavailable dependency is an unverified boundary, not
a passing test. Keep the spec open while material acceptance remains unverified.

## Material risks and unresolved decisions

- Only Press's current development tree is available. Other repositories' public `main` branches
  substantially predate the split and do not establish current local ownership or test status.
- Shared historical zenith schemas mix Access authentication and Governance authorization. Their
  final physical split cannot be inferred from actor names or old abstract record classes.
- Preferences, signals, search and non-Governance occurrence placement remain unresolved.
- Full Chronicle schemas are intentionally retained in every repository by the common-database ADR;
  unused tables alone are not permission to remove them.
- PostgreSQL NULL and partial-index semantics can exceed checker support. Preserve the correct
  contract and distinguish checker coverage from direct constraint tests.

Related current decisions: [common databases](../../adr/cosmos-common-database-connections.md),
[Base decomposition](../../adr/cosmos-base-surface-decomposition.md),
[Access/Governance separation](../../adr/cosmos-identity-authentication-global-authorization-split.md),
[Sphere independence](../../adr/cosmos-sphere-surfaces-and-rp-independence.md),
[publishing authority](../../adr/publishing-db-content-authority.md),
[cross-database references](../../adr/cross-db-reference-policy.md), and
[Press route ownership](../cosmos-press-route-ownership/spec.md).

# Press Surface Hard Reset

Status: implementing (accepted by the owner task on 2026-11-10).

## Purpose

Make this Rails application serve only Press-owned surfaces before a separate decision about unused
models and databases. The retained surfaces are Edit org, Docs, Help, Info, News and the
repository's operator tools.

## Scope

Remove foreign or retired route sets, controller trees and their exclusive views, helpers, concerns,
tests, locale keys, URL configuration and current documentation. Remove non-model application code
that becomes unreferenced, repeating until the remaining code has a caller. Keep models and
migrations for a separate report and follow-up decision.

No database is dropped, no commit is created, and unrelated worktree changes remain intact. The Edit
RP's external Auth and Visa dependencies remain because its OIDC flow uses them. Operator tool
routes with hardcoded hosts are inventoried and retained unchanged.

## Acceptance

- AC-1: Inventory every route grouped by host constraint and every controller namespace, labeling
  each OWN or FOREIGN/RETIRED.
- AC-2: Rails routes contain only Edit org, Docs, Help, Info, News, operator tools and the unknown-
  host response; deleted controller trees and their exclusive files are absent.
- AC-3: No remaining non-model application class is dead solely because its only surface was
  removed. Models and migrations remain unchanged.
- AC-4: Current host, URL, environment, test and documentation references describe only retained
  local surfaces; external Edit OIDC dependencies are identified explicitly.
- AC-5: Report model references by abstract Record database with runtime caller examples, classify
  each database, and list model-only/test-only classes for the follow-up decision.
- AC-6: Run `bin/rails zeitwerk:check`, `bin/rails routes`, `bin/rubocop`,
  `bundle exec erb_lint --lint-all`, and `bin/rails test`; record outcomes and distinguish failures
  attributable to this cleanup from baseline or environment failures.
- AC-7: Record route counts per host, deletions, removed environment variable names, retained
  foreign-looking dependencies, operator hardcoded-host route locations, verification and full
  revision in a dated evidence record. Do not expose environment values.

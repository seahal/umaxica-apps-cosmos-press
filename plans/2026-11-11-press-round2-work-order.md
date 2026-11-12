Task (umaxica-apps-cosmos-press): repair the test baseline, then cleanup round 2. Destructive
removal is approved; no compatibility layer; no commit. Never print secrets or environment values.

## Press's surfaces (the only correct list; read this first)

OWN, keep:

- docs, news, help, info: app, org and com. Press KEEPS its `.com` hosts (owner decision 2026-11-11:
  they are used). Do not remove `*_corporate` hosts, `*.com.localhost` names or corporate URL
  readers for these four surfaces.
- edit: org (`edit.umaxica.org`), the staff publishing screens; its root page stays.
- operator tools: mission, flipper, blazer, pghero, coverband, swagger
- unknown-host 404 fallback

Foreign: auth, visa (Access); base, tech (Governance); core, warp, palm (Sphere); guid, performance.
Press is a relying party; it never runs sign-in, social sign-in or OpenID Provider code.

The 2026-11-10 surface hard reset (evidence/2026-11-10-surface-hard-reset-A7K2.md) is the starting
point. Do not re-add anything it removed.

## Do not touch

config/credentials/_.yml.enc, .devcontainer/\*\*, .env_ values, docs/backlog/** (except closing the
homepage entry in Part B1), plans/**, evidence/** (except your new record), adr/**, migrations. Do
not drop tables or databases. Do not change the hardcoded operator-tool hosts (already reported).

## Part A: repair the test baseline (first)

The suite is red before any change: 117 failures and 2,495 errors after the hard reset (223 and
3,609 before it).

1. Classify the errors by cause with counts (fixtures referencing rows or tables of removed or
   foreign models, fixture load order, missing constants of removed code, missing translations).
2. Fix the causes in tests and fixtures: remove fixtures and tests that exist only for removed or
   foreign surfaces and models, and repair references in the rest. Never weaken a database
   constraint, disable foreign-key checks, skip tests or add placeholder tests to get green.
3. Re-run bin/rails test and record the new baseline with identifiers; report what remains red and
   why.

## Part B: cleanup round 2

1. No Rails homepage on info, news, help and docs, per
   docs/backlog/2026-11-10-info-news-help-docs-no-rails-homepage.md: remove `root to: "roots#index"`
   from every host block (app, org and com) in config/routes/{info,news,help,docs}.rb and delete the
   roots controllers, views, helpers, locale keys and tests used only by them. Add tests: GET / on
   each host of the four surfaces returns 404 and one retained route per surface still routes. List
   the remaining non-API page routes per surface and host. Keep the edit root. Update that backlog
   entry: `.com` stays (owner, 2026-11-11) and the homepage part is done.
2. Primary-only reads: remove `database_selector`, `database_resolver` and
   `database_resolver_context` from config/initializers/multi_db.rb; list every remaining
   `connected_to(role: :reading)`.
3. Social sign-in leftovers: remove Google and Apple entries from
   `app/values/external_authentication/provider_registry.rb` and every social sign-in code path,
   test and gem that remains only for them (their credential entries were removed on 2026-11-11).
4. `app/services/valkey/auth_state/sign_out_notice_store.rb`: delete it and its callers if no Press
   flow needs it (Press runs no sign-out ceremony of its own; sign-out happens at Access); otherwise
   report the callers.

## Checks

bin/rails zeitwerk:check, bin/rails routes, bin/rubocop, bundle exec erb_lint --lint-all, bun run
check, bin/rails test. Report test results against the Part A baseline, new failures separately.
Before finishing confirm: `config/routes/` contains docs.rb, edit.rb, help.rb, info.rb, news.rb and
the operator-tool files only; `bin/rails routes` lists no auth, visa, base, tech, core, warp, palm,
guid or performance host, no root route for info, news, help or docs on any host, and still lists
the `.com` hosts of those four surfaces.

## Report

Record in evidence/YYYY-MM-DD-press-round2-XXXX.md (full `git rev-parse HEAD`; note that uncommitted
changes affected results): error classification and fixes, new test baseline, removed paths summary,
remaining page routes per surface and host, remaining reading-role uses, check results. No commit.

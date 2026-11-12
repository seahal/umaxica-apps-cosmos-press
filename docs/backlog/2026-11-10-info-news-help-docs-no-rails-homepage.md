# Info, News, Help and Docs: Rails Serves No Homepage (2026-11-10)

Owner: Press (`info`, `news`, `help`, `docs`). Status: homepage work complete (2026-11-11).

## Decision (owner, 2026-11-10)

Like Auth, Visa, Base and Core (`adr/cosmos-base-surface-decomposition.md`, decision 9; Sphere's
`docs/backlog/2026-11-10-core-edge-front-and-no-rails-homepage.md`), Rails `info`, `news`, `help`
and `docs` answer `/` with 404 on app, com and org. Reason: a Rails homepage on a hostname whose
pages may be served elsewhere makes it unclear which one answers, and a routing or tunnel mistake
would silently show the Rails page ("it causes accidents").

Today each surface draws `root to: "roots#index"` on every host block: `config/routes/info.rb`,
`config/routes/news.rb`, `config/routes/help.rb` and `config/routes/docs.rb` (three blocks each).

## Completed (homepage decision, 2026-11-11)

- Press keeps the `.com` hosts of Info, News, Help and Docs because they are used. The Edit root
  page also stays.
- The Rails homepage routes are removed from all twelve content host blocks; `GET /` returns 404.
  The Edit root remains.
- The remaining non-API routes are revision metadata, health checks and CSP reporting. No content
  page route remains on these surfaces. The README does not name a separate component that serves
  content pages on these hosts.

## Work order (Codex, this repository)

```
Make Rails info, news, help and docs serve no homepage:
- Remove the root route (`root to: "roots#index"`) from every host block in
  config/routes/{info,news,help,docs}.rb, and delete the roots controllers, views, helpers,
  locale keys and tests that only served those homepages.
- Add tests: GET / on each host of the four surfaces (app, com, org, and the *.localhost names)
  returns 404; one retained route per surface still routes.
- The route inventory and verification results are recorded in
  [`evidence/2026-11-11-press-round2-R8C4.md`](../../evidence/2026-11-11-press-round2-R8C4.md); do not remove the remaining runtime routes in this
  task.
- Do not change authentication, OIDC callback or CSRF behavior. Run bin/rails zeitwerk:check,
  bin/rubocop, bundle exec erb_lint --lint-all and the affected tests. No commit.
```

# Rails surface view inventory

This inventory records the current Rails HTML views. Route and controller ownership is limited to
Edit org, Docs, Help, Info, News, and the host-constrained operator tools. The historical UI audit
that preceded the hard reset is preserved in Git history; its Auth, Base, Core, Palm, Tech, Visa and
Warp rows no longer describe this application.

## Public content surfaces

The content surfaces have no Rails HTML views. Their app, com and org hosts keep health, revision,
CSP-report and read-only API endpoints. Browser pages are served outside Rails.

The API, health, revision and CSP-report endpoints do not add views or authenticated navigation.

## Edit org

The Edit layout is `app/views/layouts/edit/org/application.html.erb`. Its views cover the root,
dashboard, publishing entry list/detail/new/edit, sign-out outcomes and step-up challenge. Shared
content entry templates render published content; shared OIDC RP templates render sign-in and
interruption outcomes. Shared UI partials provide the button, skip link and standalone ceremony
style.

Edit's browser sign-in delegates to the configured external Auth/Visa OIDC service. The external
service is a dependency of this relying party and does not add Auth or Visa routes to this app.

## Operator tools

Mission, Flipper, Blazer, PgHero, Swagger and Coverband are host-constrained mounts. Their rendered
views are owned by their Rack applications or engines rather than `app/views`.

## Stylesheets

There are thirteen owned Vite CSS entrypoints: one for Edit org and one for each content family and
audience. Each imports the shared theme and base CSS. There are no Rails JavaScript entrypoints or
client component trees.

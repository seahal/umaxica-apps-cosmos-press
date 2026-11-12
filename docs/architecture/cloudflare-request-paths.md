# Cloudflare Request Paths and Trust Boundaries

This document records the current Press ingress boundary. Cloudflare owns the tunnel and Access
configuration; this repository owns Rails host authorization, route constraints and application
authorization.

## Routes served by Press

The only application surfaces hosted here are Edit (`org`), Info, Docs, News and Help (`app`, `com`,
`org`), plus Mission, Flipper, Blazer, PgHero, Swagger and Coverband. See
[`README.md`](../../README.md) for the surface inventory. Each route set constrains its hosts in
`config/routes/`. Unmatched hosts reach the `unknown_hosts` response.

Auth, Base and Visa remain external dependencies of Edit's OIDC relying-party flow. Base origins
also supply existing preference and mail-link domain values. These origins are not local Rails hosts
or routes. Core, Palm, Tech and Warp are not hosted by this repository.

## Host authorization

Every route has a host constraint. Production host authorization is assembled from the same Docs,
News, Help, Info and Edit origins plus the six fixed operator-tool hosts in
`config/environments/production.rb`. External Auth, Base and Visa origins are excluded from the
inbound allowlist.

Development host authorization admits the configured origins for those Press routes, their
`*.localhost` development aliases, and the operator-tool aliases. The URL variable names read for
this allowlist are listed in `config/environments/development.rb`; the values stay in environment
configuration. The externally hosted Auth, Base and Visa URLs are not inbound host entries.

Rails evaluates the request's `Host` header against `config.hosts`; a container or tunnel routing
target does not grant a host permission. `config/routes/` separately constrains each application
surface. Cloudflare Access is a perimeter for published development hosts, while Rails continues to
enforce the application's own authentication and authorization.

## Operator tools

The six operator tools are mounted Rails engines or Rack applications with their own route host
constraints. Their canonical public hosts are hard-coded in the route files and are also included in
the production host allowlist. In development, their configured private origins and local aliases
are admitted. The route-local host declarations are intentionally retained; see the surface hard
reset evidence for their exact file and line locations.

Mounted tools do not inherit the application controller's callbacks. Their access controls are
configured at each engine or Rack boundary, independently of public content and Edit authorization.

## Cloudflare-owned settings

The Cloudflare account owns DNS, tunnel ingress, Access applications and policies. Repository
changes cannot prove that those remote settings match the route inventory. Check the current account
configuration when publishing or changing an ingress, and preserve the distinction between the
external routing target and the hostname Rails receives. See
[`cloudflare-private-origin.md`](../operations/cloudflare-private-origin.md) for the operational
procedure.

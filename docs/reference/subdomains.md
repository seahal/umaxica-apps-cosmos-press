# Host and Surface Map

Host constraints select a Rails surface. They do not imply shared credentials, sessions or
authorization between hosts.

## Retained Rails surfaces

| Surface                                              | Audiences           | Purpose                                             |
| ---------------------------------------------------- | ------------------- | --------------------------------------------------- |
| `edit`                                               | org                 | Staff publishing and the Edit browser relying party |
| `docs`, `help`, `info`, `news`                       | app, com, org       | Public content pages and read APIs                  |
| Mission, Flipper, Blazer, PgHero, Swagger, Coverband | operator tool hosts | Operations and diagnostics                          |

Development content hosts use `<family>.<audience>.localhost`; Edit uses `edit.org.localhost`.
Operator tools retain the route-local development aliases in `config/routes/*.rb`. Canonical
production hostnames and private service URLs come from required boot configuration; this document
does not duplicate environment values.

## External sign-in dependency

Edit org is an OIDC relying party. It delegates sign-in and provider-side authentication to the
configured external Auth/Visa service. This application does not host Auth, Base, Core, Palm, Tech,
Visa or Warp routes. Their local host labels are not added to Rails Host Authorization.

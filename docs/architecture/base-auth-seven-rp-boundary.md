# Edit RP and External Provider Boundary

This application currently exposes one local browser relying party: Edit org. The RP implementation
owns its callback, browser session, publishing UI, and route host. It delegates authentication to
external Auth and Visa services through OIDC.

| Role              | Owner                 | Local Rails routes                                                            |
| ----------------- | --------------------- | ----------------------------------------------------------------------------- |
| Browser RP        | Edit org              | `GET/POST /sign`, `GET /oidc/callback`, sign-out, and local publishing routes |
| Ceremony provider | External Auth service | None in this repository                                                       |
| OIDC authority    | External Visa service | None in this repository                                                       |

Docs, Help, Info and News are independent public content surfaces. Mission, Flipper, Blazer, PgHero,
Swagger and Coverband are operator tools. Neither group shares Edit's credentials or session.

The former Base/Auth seven-RP map is historical. Its route and controller inventory was retired as
part of the [surface hard reset](../../evidence/2026-11-10-surface-hard-reset-A7K2.md); persisted
models and migrations are reported there for a separate follow-up decision.

The accepted historical decisions remain available in
[`adr/base-auth-ceremony-and-seven-rp-boundary.md`](../../adr/base-auth-ceremony-and-seven-rp-boundary.md)
and
[`adr/oidc-oauth-participation-allowlist-and-non-participant-surfaces.md`](../../adr/oidc-oauth-participation-allowlist-and-non-participant-surfaces.md).

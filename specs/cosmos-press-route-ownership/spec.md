# Cosmos Press Route Ownership

Status: implementing (accepted 2026-11-08). GUID retirement and Press operator hostname changes are
in progress; the remaining surface ownership changes are deferred.

## Purpose

The four Cosmos repositories (`umaxica-apps-cosmos-access`, `-governance`, `-sphere`, `-press`)
still contain the same Rails application and draw every subdomain. This change assigns the content
subdomains to Press and removes them from the other three repositories, as the first step toward
each repository owning only its own routes, code and database connections.

The responsibility split follows `adr/cosmos-identity-authentication-global-authorization-split.md`
(Identity is now Access, Global is now Governance, Regional is now Sphere). This spec does not amend
that ADR.

## Decision

| Repository                    | Keeps                                                                                                 | Removes                                                        |
| ----------------------------- | ----------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| Press                         | `edit`, `info`, `news`, `help`, `docs`, and its own `.dev` operator tools                             | `visa`, `auth`, `base`, `core`, `palm`, `warp`, `tech`, `guid` |
| Access, Governance and Sphere | their own subdomains (`adr/cosmos-base-surface-decomposition.md`) and their own `.dev` operator tools | `edit`, `info`, `news`, `help`, `docs`, `guid`                 |

Other decisions recorded in the same discussion, outside this spec's scope:

- Sphere owns `core`, `palm` and `warp`; Access owns `visa` and `auth`; Governance owns `tech`.
- `base` is decomposed by `adr/cosmos-base-surface-decomposition.md`: Governance takes it, and its
  org publishing API (docs, help, info and news entries and archives) moves to Press `edit`.
- The split is a hard reset: each repository uses only its own databases from the first step
  (`adr/cosmos-base-surface-decomposition.md`, First Step).
- `guid` is retired in all four repositories (decided 2026-11-09). Its routes and controllers are
  removed with the other unowned subdomains; identifier code that kept code still calls stays.
- Every repository keeps and owns its own `.dev` operator tools (`mission`, `flipper`, `blazer`,
  `pghero`, `swagger`, `performance`, `coverband`; decided 2026-11-09). Each serves them on its own
  hostnames, `<tool>-<repository>.umaxica.dev` (Sphere: `<tool>-sphere-jp.umaxica.dev`), as listed
  in `plans/2026-11-08-cloudflare-tunnel-split.md`. Access's settings are the reference for the
  other three.
- Every application keeps its own revision endpoint mechanism; `info` itself is Press-only.

## Scope

In scope: route drawing (`config/routes.rb`, `config/routes/*.rb`), the removed subdomains'
controllers, views and tests, and the route-specific configuration that becomes unreachable.

Out of scope: OIDC issuers, client IDs and redirect URIs, database schemas, physical databases and
ADR revisions. Reworking `edit`'s RP authentication onto the local-cell path follows the Governance
Base App pattern and is tracked there. Removing a database connection from `config/database.yml` is
a separate decision; dropping a database is not part of this work.

## Observations (read-only survey, 2026-11-08)

Observed in `umaxica-apps-cosmos-access` at `281a9e5c5`; the four repositories were identical at
that point apart from naming.

- `info`, `news`, `help` and `docs` controllers use only `PublishingRecord` (`publishing`) directly
  and include no authentication concern. They can move without authentication changes.
- `edit`, `core`, `palm` and `warp` are browser RPs. Their base controllers include
  `BrowserRpAuthentication`, which has a local-cell path (public JWKS and the RP's own session
  store) and a legacy path that reads Access-owned databases; `SessionLimitGate` reads `op_base_*`
  when resolving session limits, and `AuthorizationAudit` writes `chronicle`. Removing routes does
  not by itself remove these dependencies.
- `lib/runtime_role.rb` and `config/initializers/runtime_role_route_guard.rb` already restrict a
  role process to the controllers its role owns (`rp-edit-org-ww`, `domain-publishing`, and others).
  Development runs every surface as the transitional `shared` role.

## Risks

- With `visa`, `auth` and `base` removed from Press, `edit` sign-in must complete against Access's
  hosts. In development, Press and Access must run together to sign in to `edit`. This has not been
  verified.
- Shared concerns, jobs and models used by removed controllers may still be needed by kept code;
  delete only what has no remaining caller.

## Acceptance

- AC-1: Press draws only `edit`, `info`, `news`, `help`, `docs` and its own `.dev` operator tool
  routes; requests to any removed subdomain host are not routed.
- AC-2: Access, Governance and Sphere do not draw `edit`, `info`, `news`, `help`, `docs` or `guid`.
- AC-3: Each repository boots and its remaining test suite passes after the removal.
- AC-4: `edit` sign-in completes through Access's `visa`/`auth` hosts, with the result recorded in
  `evidence/`.
- AC-5: OIDC client registrations, redirect URIs and schemas are unchanged. Existing development
  data may break under the hard reset; deleting volumes or data needs the owner's approval.

## Order

1. Remove `info`, `news`, `help` and `docs` from Access, Governance and Sphere, and remove the
   non-content subdomains other than `edit` from Press.
2. Remove `edit` from the other three repositories, move the Base org publishing API to `edit`, and
   confirm AC-4 once `edit` authenticates on the local-cell path.
3. Follow-up, separate decision: remove database connections that no remaining code uses. Expected
   candidates are `publishing` outside Press, and `rp_core_*`, `rp_warp_*`, `rp_palm_app` and
   `rp_tech_org` in Press. `op_base_*`, `rp_base_*` and principals stay until `edit` no longer uses
   the legacy authentication path; Press keeps its own `chronicle`. `*_setting`, `*_signal`,
   `occurrence`, `avatar` and `search` usage has not been surveyed.

## Implementation clarification (2026-11-09)

For Access, Governance and Sphere, this implementation removes only the surfaces named in AC-2 and
Order 1/2: Info, News, Help, Docs, Edit and GUID. Other family route draws remain for a later
decision; the broader ownership rows above do not expand this implementation.

Press removes the non-content surfaces named by Order 1 while retaining Edit, the four publishing
surfaces and its seven operator tools. The Base org publishing API moves to the Edit host and
controller namespace as required by the Base decomposition ADR. The Edit layout's Base Preferences
link is removed while Preferences ownership remains open; no replacement link is introduced.

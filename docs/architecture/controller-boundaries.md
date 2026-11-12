# Controller Boundaries

The Rails application serves only these controller families:

- `Docs`, `Help`, `Info` and `News`, each split by app, com and org audience.
- `Edit::Org`, which owns staff publishing and the browser relying-party flow.
- `UnknownHostsController`, which handles unmatched hosts.
- Rails and mounted operator-tool controllers under their host constraints.

There are no local Auth, Base, Core, Palm, Tech, Visa or Warp controller trees. Edit's OIDC flow
uses its configured external Auth/Visa provider; those provider surfaces remain outside this app.

## Content controllers

The content families own public roots, read-only content APIs, health and revision endpoints, and
the CSP report sink. Their bare controllers bypass the Edit authentication-aware lifecycle. Keep
content reads independent of actor credentials, sessions and Edit request state.

## Edit controllers

`Edit::Org::ApplicationController` owns the authenticated publishing interface and Edit's browser
relying-party boundary. Its authentication, verification, authorization and session behavior stays
local to Edit. Provider callbacks and server-to-server publishing APIs retain their
protocol-specific guards.

Concrete controller/action metadata and policies remain the authority for admission. Missing or
unclassified actions fail closed. Do not infer access from a route name, host label, or controller
inheritance alone.

## Operator tools and unknown hosts

Each operator tool is mounted behind its own host constraint and configured credential check. An
unknown host reaches only the explicit unknown-host response. Framework and engine routes must not
become reachable on another surface by removing or weakening those boundaries.

# Local Routes Outside the Edit RP

The Rails application serves four public content families, the Edit org publishing tool, the
repository's operator tools and an unknown-host response. The content pages do not participate in
OAuth or OIDC. Their host ownership and route families are listed in the
[content surface matrix](content-surface-matrix.md).

Edit org is the only local browser relying party. Its sign-in flow delegates to the externally
configured Auth ceremony and Visa authorization services; those providers are not mounted as Rails
surfaces in this repository. Provider protocols remain dependencies of Edit and do not make their
routes or sessions local application routes.

Mission, Flipper, Blazer, PgHero, Swagger and Coverband remain operator-only mounts. Each has its
own host constraint and authentication boundary. They do not participate in the Edit browser
session.

The retired Auth, Base, Core, Palm, Tech, Visa and Warp controller trees and their route sets are
absent. The retained models and database history are outside this routing boundary and are reported
in the surface hard-reset evidence for a later database/model decision.

The historical participation decision remains in
[`adr/oidc-oauth-participation-allowlist-and-non-participant-surfaces.md`](../../adr/oidc-oauth-participation-allowlist-and-non-participant-surfaces.md).

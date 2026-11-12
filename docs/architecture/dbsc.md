# Device Bound Session Credentials (DBSC)

This checkout no longer serves a DBSC registration or verification endpoint. The DBSC route and
controller stack, registration and proof-verification services, HTTP header parsers, and persistence
adapter were removed in the Press surface hard reset on 2026-11-10.

Existing client and operator token models, their DBSC columns, status references, and migrations
remain in the repository. `DbscBindable` still reads those persisted values and validates the
session identifier's uniqueness. No current route issues a DBSC challenge or writes a DBSC
registration. The downgrade helper was also removed with the registration workflow. Those stored
models and migrations are retained for the separately authorized database/model cleanup step.

The presence of those persisted columns does not mean browser cookies are currently bound to a
device key. This document records repository behavior; it makes no claim about deployed data or
browser interoperability.

For current token-binding behavior, see [DPoP](dpop.md). For the retained DBSC state fields and
references, use the model/database inventory in the surface hard-reset evidence.

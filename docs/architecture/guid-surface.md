# Retired GUID surface

The GUID HTTP surface was retired on 2026-11-09 under the accepted
[Cosmos Press route ownership specification](../../specs/cosmos-press-route-ownership/spec.md).
Press no longer draws its routes or provides its controllers, views, health profile or host
configuration. The former public and development hosts have no GUID endpoint or compatibility
redirect.

This retirement removes only the dedicated HTTP surface. Existing identifier generation,
blind-index, encryption and WebAuthn identifier processing remain with their current owners. It does
not change issued identifiers, database schemas, persistent data or resource identity.

The [retired GUID ADR](../../adr/guid-identifier-surface.md) preserves the former bootstrap decision
as history. A future identifier service requires a new accepted decision.

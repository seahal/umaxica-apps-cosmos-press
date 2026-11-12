# Edit Authorization

Applies to Edit org publishing UI and API operations. Public content surfaces are read-only and do
not inherit Edit's session or authorization state.

- AUTHZ-1: Server-side authorization protects every mutation regardless of hidden or disabled UI
  controls.
- AUTHZ-2: Entry and publication lookup preserve the selected content family and audience; an
  identifier from another cell does not gain access through a nested route.
- AUTHZ-3: Publishing API and browser mutations authorize the loaded entry and action before
  persistence. A response stub or hidden control does not bypass policy evaluation.
- AUTHZ-4: A Step-Up result authorizes only an operation whose purpose, actor, resource, tenant,
  session, transaction, freshness and method requirements it satisfies; an assurance label alone
  does not grant access.

Sources: [Action Policy conventions](../security/action-policy-conventions.md),
[content ownership](../architecture/content-surface-matrix.md), and
[the API design standard](../reference/api-design-standards.md). These are required behaviors; their
presence is not evidence of execution.

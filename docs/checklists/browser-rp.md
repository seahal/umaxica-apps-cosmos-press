# Edit Browser RP

Edit org is the only local browser relying party in Press. These are durable requirements, not
current verification results. The sign-out contract is in [sign-out](sign-out.md).

- BRP-10: Edit holds at most one pending OIDC sign-in entry per browser. The last `POST /sign` wins;
  an earlier tab may continue through the external Auth/Visa flow but its callback is refused at
  `GET /sign/interruption`. This is per browser, does not cancel another browser's registration, and
  does not replace Rails CSRF, PKCE, nonce or state verification.
- BRP-11: Press registers only its `edit-org-ww` callback on the Edit org host, including explicitly
  configured public and private Edit origins. Other realms and sibling RP client IDs are refused.
  Edit uses external Auth and Visa protocol boundaries and inherits no sibling RP session. See
  [Press URL dependencies](../../specs/press-surface-url-dependencies/spec.md).
- BRP-12: Edit callback state digests are unique before model persistence and under direct database
  writes. Consuming a callback does not release its digest for reuse.
- BRP-9: The retired Xper public and local hosts serve none of their former paths through Xper or
  another surface, while the same paths on retained hosts still answer.

Sources: [the Edit RP boundary](../architecture/base-auth-seven-rp-boundary.md),
[Xper retirement](../../adr/xper-rails-surface-retirement.md), and
[OIDC participation history](../../adr/oidc-oauth-participation-allowlist-and-non-participant-surfaces.md).

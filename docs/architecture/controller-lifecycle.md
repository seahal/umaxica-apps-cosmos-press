# Controller Lifecycle

This guide covers the Rails controller request lifecycle for the retained surfaces. Read it with
`docs/architecture/controller-boundaries.md` and the authentication, session and publishing
contracts referenced by the owning code.

## Ownership

- Content-family controllers own public reads and infrastructure endpoints without actor lifecycle.
- Edit org controllers own the staff publishing interface and Edit's OIDC relying-party session.
- Operator tools own their mounted request handling behind host-local credentials.

Authentication and authorization stay with Edit controllers and their existing concerns and
policies. Content controllers do not inherit Edit credentials, preferences, actors or sessions.

## Request order

For authentication-aware Edit actions, preserve the order declared by the surface controller and its
concerns: request self-defense and rate limiting; credential and session resolution; actor and
request-local preference setup; action authorization; action execution; audit/response handling; and
guaranteed request-state cleanup. A failure in an earlier stage must prevent later mutations.

Protocol endpoints retain their own checks. OIDC callbacks validate state, nonce, PKCE and callback
binding before consuming the transaction. Publishing APIs authenticate the caller and reapply the
publishing policy. Sign-out and step-up flows preserve their transaction and session boundaries.

## Change rule

Before changing a callback, identify the concrete route, controller/action, authorization policy,
and transition writer. Keep request state explicit and request-local. Add or update a behavior test
at the affected public boundary, then update the owning current contract when its behavior changes.

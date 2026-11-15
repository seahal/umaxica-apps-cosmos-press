# Jump handoff

Applies to Rails issuing return tokens to Jump and verifying tokens returned by Jump, on every Jump
node surface. The contract is the local Jump 0.4.0 compatibility baseline, not a deployed contract.
These are durable requirements, not current verification results.

- JUMP-1: A token is issued only for an explicit `internal` destination. A missing, `external`,
  array, object or unknown value is refused without inference, rewriting or a direct external
  redirect.
- JUMP-2: An issued compact JWT is at most 4,096 characters and its `url` claim at most 2,048 UTF-16
  code units; the issue TTL is positive and at most 30 seconds. A returned JWT over 8,192 bytes is
  refused before parsing; `exp - iat` above 30 seconds is refused, and the 5-second clock skew never
  extends it. Nothing is truncated to fit.
- JUMP-3: Press has no local Jump issuer namespace. Edit remains an OIDC assertion client without
  Jump issuance authority, and the deployment's return policy refuses sibling-repository edges.
  Gateway protocol fixture tests may resolve exact fixture identities while retaining real
  directed-edge checks; they do not establish a deployed Press acceptance edge.
- JUMP-4: Duplicate `rt`, `rt[]` and nested forms and duplicated single-value parameters are
  refused; query order and `%20` / `+` / `%2B` are compared without converting the URL to a Hash. A
  return URL whose path starts with `//` is refused before it can become a protocol-relative
  redirect.
- JUMP-5: A returned token is refused for a bad signature, `alg`, `typ`, unknown or revoked `kid`,
  issuer, audience, `src`, times, and unknown, missing or wrongly typed claims. `rpl: "reuse"` is
  kept; one-time semantics belong to the receiving flow. `src` is an origin without a path, query,
  or fragment.
- JUMP-6: A fetched Jump JWKS document over 64 KiB or with more than 10 keys is refused.
- JUMP-7: The Rails Jump return verifier accepts PS256 only and refuses an ES384 token. Imported
  keys are RSA, public-only JWKs with `alg=PS256`, `use=sig`, and a modulus of at least 3072 bits.
  Protocol fixtures exercise this policy; they do not verify the external Jump deployment.

Sources: [Jump handoff contract](../../adr/jump-directed-rails-handoff-contract.md),
[Jump redirector](../../adr/secure-jump-link-redirector.md).

Press ownership: [surface URL dependencies](../../specs/press-surface-url-dependencies/spec.md).

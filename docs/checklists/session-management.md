# Session management

Applies to session establishment, pending sign-in and revocation on the Edit org browser RP.

- SESSION-1: A successful session-establishment result means committed session authority; pending
  sign-in and recorded authentication evidence do not masquerade as an issued session.
- SESSION-2: Cookies, current-resource state and success audit follow the committed establishment; a
  refusal or failed transaction does not produce success state.
- SESSION-3: Root-login cooldown uses the root-login establishment anchor, not refresh, step-up or
  RP connection times; refusal does not disclose account existence or the remaining interval.
- SESSION-4: Issuance and revocation failures remain failures; database errors are not treated as
  absent sessions or successful revocations.
- SESSION-5: A DPoP-bound RP Access JWT is accepted only with the DPoP authorization scheme and a
  valid proof bound to the request method, URI, token hash and confirmation key. Missing or invalid
  proof is an explicit authentication refusal.
- SESSION-6: DPoP replay and nonce state is short-lived and purged by its scheduled job; logs never
  contain proof, nonce, token or key material.

- SESSION-7: Across all surfaces, application-signed and encrypted messages accept JSON only.
  Authenticated Marshal payloads are refused without a legacy-reader fallback
  ([message serializer configuration](../../config/application.rb)).

Sources: [root-login boundary](../../adr/root-login-establishment-boundary.md),
[session issuance rule](../../.agents/harnesses/rules/project/session-issuance.mdc), and
[DPoP behavior](../architecture/dpop.md). Local DBSC HTTP registration and verification routes were
retired on 2026-11-10; the remaining token columns are covered by the surface hard-reset model
inventory. Implementation paths and test inventory remain in those sources; this list records no
test result.

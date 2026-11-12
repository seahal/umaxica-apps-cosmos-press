# OAuth 2.0 Demonstrating Proof of Possession (DPoP)

This checkout uses DPoP only when authenticating a DPoP-bound Access JWT at the Edit ORG browser RP.
Local Auth, Core and Palm token issuance routes were retired in the Press surface hard reset on
2026-11-10; they are not current DPoP consumers.

## Edit RP request boundary

`BrowserRpAuthentication` passes the Access JWT, authorization scheme, DPoP proof and request
details to `OidcAccessTokenAuthenticator`. A token with a `cnf.jkt` confirmation key is accepted
only with the `DPoP` authorization scheme and a proof that validates against the current request and
token. Missing or invalid proof refuses authentication. An unbound token follows the normal
bearer-token path.

The current implementation is in:

- `app/services/oidc_access_token_authenticator.rb` — selects the bound or unbound path.
- `app/services/dpop_request_verifier.rb` and `app/lib/dpop_proof_verifier.rb` — validates the
  proof.
- `app/services/dpop_nonce_service.rb` and `app/services/dpop_jti_replay_guard.rb` — manage nonce
  and replay state.
- `app/jobs/dpop_proof_state_purge_job.rb` — removes expired proof-state rows on its recurring
  schedule.

Supported proof algorithms, claim checks, nonce handling and state retention are defined by those
implementation files and their tests. DPoP proof, nonce, access token and key material must not be
written to application logs.

## Retained data and retired transports

The Client and Operator token/session models retain `dpop_jkt` fields and the App/ORG ticket stores
retain proof-state tables. Their existence does not add a DPoP route or permit a new DPoP issuance
flow. The static model/database inventory records those retained models and current production
callers.

DBSC is a separate browser-cookie binding mechanism. Its registration and verification routes and
writers were retired; persisted token DBSC columns remain pending the next model/database cleanup
step. See [DBSC](dbsc.md).

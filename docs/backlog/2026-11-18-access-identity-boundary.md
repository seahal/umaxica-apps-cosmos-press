# Evidence needed at the Press and Access identity boundary

Open for triage. Static review of Press revision `57c72d323dd157fcacd7aef2e145d9bf0d8132e6` on
2026-11-18. Edit is the staff browser relying party (RP). Access owns the external authentication
and OIDC provider (OP). The conclusions below cover local code. Validation of Access and deployed
environment settings remains pending. [Press routing ownership](../../README.md#L8),
[Edit routes](../../config/routes/edit.rb#L49).

## OIDC checks in Edit

- Sign-in begins with a CSRF-protected POST. Edit generates a random PKCE verifier and nonce, uses
  S256, selects a registered callback URI for the request host and sends that same registered URI in
  the code exchange. An unregistered host fails selection. The RP also compares the authorization
  response issuer with the configured issuer. Access owns exact matching against its client
  registration and atomic consumption of the code.
  [CSRF](../../app/controllers/edit/org/application_controller.rb#L61),
  [sign entry](../../app/controllers/concerns/oidc_rp_sign_entry.rb#L16),
  [PKCE and nonce](../../app/controllers/concerns/oidc_sso_initiator.rb#L68),
  [URI selection](../../app/controllers/concerns/oidc_sso_initiator.rb#L160),
  [exchange and issuer check](../../app/controllers/concerns/oidc_callback.rb#L92).
- The ID and access token verifiers require PS256 and the appropriate token type, reject
  token-supplied key URLs, and verify the signature using the configured issuer's JWKS. Each
  requires a single, exact audience, the expected issuer and integer time claims, with a 30-second
  clock allowance. The ID token verifier also binds the nonce and actor type. Edit additionally
  checks the access token's client and the local session's subject and session ID. The logout token
  has a dedicated event, audience, issuer, signature and lifetime check.
  [ID token checks](../../app/adapters/oidc_op_id_token_verifier.rb#L116),
  [access token checks](../../app/adapters/oidc_op_access_token_verifier.rb#L82),
  [issuer and key source](../../app/controllers/concerns/rp_cell_local_session.rb#L23),
  [local binding](../../app/services/rp_request_authenticator.rb#L80),
  [logout token checks](../../app/adapters/oidc_op_logout_token_verifier.rb#L36).
- Deployment isolation depends on the issuer derived from the configured staff authority, its
  trusted signing keys and the RP registration. A token naming a different issuer or audience fails
  locally. Establish whether staging and production actually use distinct issuers and appropriate
  key material from sanitized deployment and registration records. Verify which callback URIs each
  environment registers at Access. [Staff issuer selection](../../app/values/oidc_issuer.rb#L45),
  [Edit registration](../../app/values/oidc_client_stores_static_client_store.rb#L24),
  [registered URI rules](../../app/values/oidc_client_stores_static_client_store.rb#L75).

## Scope of the one-use state check

Edit signs the OIDC state with a 30-minute lifetime. It stores the corresponding verifier and nonce
in the browser's encrypted Rails session cookie. A normal callback removes the pending entry from
the cookie returned to that browser. Concurrent requests carrying the earlier cookie can each start
with the same pending state. Press has no atomic server-side consumption at this step. The existing
replay test uses the updated cookie. Access's one-use code and Edit's refusal to enroll an
already-live session provide separate protections. The review did not establish duplicate
authentication or account compromise. [State token](../../app/values/oidc_state_jwt.rb#L13),
[cookie store](../../config/initializers/session_store.rb#L9),
[pending entry](../../app/controllers/concerns/oidc_sso_initiator.rb#L138),
[consumption](../../app/controllers/concerns/oidc_callback.rb#L313),
[local enrollment check](../../app/operations/rp_callback_committer.rb#L68),
[replay test](../../test/integration/edit_org_oidc_callback_test.rb#L92).

Decide whether the intended guarantee is one exchange attempt per state at Edit, or one successful
use of a code at Access. Closure requires the owning contract and evidence for concurrent callbacks,
reissued browser cookies and code consumption at the selected boundary. The separate return-target
backlog concerns disclosure of a path embedded in signed state.
[Return-target backlog](2026-10-23-rp-target-link-uri-path-exposure.md).

## Access evidence to collect when selected

Press exposes sign initiation and callback, plus an authenticated step-up route that returns 503. It
has no local account registration, email confirmation, password reset, invitation issuance, or
OTP/SMS delivery controller in the route inventory. Edit accepts a verified operator identity and
does not itself check an email-verification claim. Public content is available to anonymous readers.
The authority decides whether an unverified account can obtain an operator token.
[Route inventory](../../config/routes.rb#L4),
[Edit verification](../../app/controllers/edit/org/verifications_controller.rb#L12),
[callback acceptance](../../app/controllers/concerns/oidc_callback.rb#L60),
[public content ownership](../../README.md#L8).

| Owner question                                                                                                    | Evidence needed for a decision                                                                                                                                                                                                                                                                                                                                                                 |
| ----------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Which registration and sign-in operations exist, and which features can an account use before email confirmation? | Map the current Access routes to server-side challenge/CAPTCHA, input checks, account state transitions and token issuance. Identify each operation permitted before confirmation.                                                                                                                                                                                                             |
| Which forgotten-password and invitation flows issue tokens?                                                       | For each implemented flow, identify the random source and entropy, purpose and recipient binding, expiry check, storage and atomic one-use transition, including concurrent use and reissue. If a flow is absent, record the owning route inventory.                                                                                                                                           |
| Who enforces limits for login, confirmation or resend, password reset, invitation, and OTP/SMS delivery?          | Attribute each limit to the application, CDN/WAF, identity provider or transport provider. Record the identity counted, window, failure behavior and whether capacity is reserved before delivery.                                                                                                                                                                                             |
| Can a response disclose account or token existence?                                                               | Compare equivalent present and absent cases at the owning service for status, response text and size, redirects and timing. Press sends many callback failures to a common interruption page and has a distinct dependency-failure response. This review collected no timing or response-size measurements. [Callback failure handling](../../app/controllers/concerns/oidc_callback.rb#L224). |

Prior entries record narrower questions and historical observations. Use them to locate the
appropriate owner and confirm the current deployment before treating a limit or workflow as
implemented. [Login limits](2026-10-22-login-rate-limit-guarantees.md),
[email signup](2026-10-22-email-sign-up-delivery-limits.md),
[confirmation resend](2026-10-22-sign-up-confirmation-resend-limits.md),
[reset](2026-10-22-password-reset-abuse-policy.md),
[invitation](2026-10-22-invitation-email-abuse-policy.md),
[sign-in OTP](2026-10-22-sign-in-otp-resend-limits.md),
[telephone signup](2026-10-22-telephone-sign-up-delivery-limits.md). The Edit session backlog covers
credential lifetime and revocation after account changes.
[Edit session revocation](2026-11-18-edit-session-revocation.md).

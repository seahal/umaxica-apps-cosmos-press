# Edit logout after access-token expiry and the revocation window

Open for triage. Static review of Press revision `57c72d323dd157fcacd7aef2e145d9bf0d8132e6` on
2026-11-18. The deployed identity provider and browser were outside this review. Implementation
choices remain open.

## A renewable session can survive a logout request

The Edit sign-out controller inherits from the bare controller. Its POST requires a valid access
cookie and a live local session. If the access cookie has expired or disappeared, the action returns
401 before revoking the local row or clearing the cookies. A browser with a live local session and
usable refresh credential can still renew access on an ordinary Edit page. This matters when the
access credential expires while the user is on the sign-out confirmation page. The user receives a
failure response and the renewable session remains active.
[Controller and callback](../../app/controllers/edit/org/sign/outs_controller.rb#L33),
[credential resolution](../../app/controllers/concerns/oidc_rp_logout_launcher.rb#L133),
[401 response](../../app/controllers/concerns/oidc_rp_logout_launcher.rb#L21),
[ordinary page refresh](../../app/controllers/concerns/browser_rp_safe_request_refresh.rb#L11),
[refresh checks](../../app/operations/rp_refresh_committer.rb#L116).

When authentication succeeds, Edit locks the local session on its writer and records revocation
before clearing cookies. It attempts remote revocation of a refresh token bound to the same session.
A remote refusal is logged and the OP logout handoff continues. A local persistence failure returns
503 before success is reported. A copied local credential pair therefore loses Edit access after a
successful local commit. The result of the remote call and the user's eventual decision at the OP
are separate facts.
[Local commit and failure](../../app/controllers/concerns/oidc_rp_logout_launcher.rb#L55),
[cookie clearing and handoff](../../app/controllers/concerns/oidc_rp_logout_launcher.rb#L111),
[refresh-token binding and remote result](../../app/controllers/concerns/oidc_rp_logout_launcher.rb#L150),
[sign-out checklist](../checklists/sign-out.md#L11).

## Which changes reach an issued credential

| Event                                                                                | What Press establishes                                                                                                                                                                                                                                                                                                          | Evidence needed from the owner                                                                                                                                       |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Local principal disabled, local session revoked, or OP binding revoked in Edit       | Each authenticated request verifies the access JWT and reads the writer. It checks the live session, absolute expiry, local principal, issuer, realm, client, subject and session binding. Refresh also rechecks local state before installation.                                                                               | How a canonical account change reaches every affected Edit binding.                                                                                                  |
| Verified OP logout notification                                                      | In one transaction Edit records a replay receipt, marks the session binding revoked and revokes its sessions. A late callback for that binding is refused.                                                                                                                                                                      | Delivery coverage, delay, retries and recovery in the deployment.                                                                                                    |
| OP logout before Edit receives the notification                                      | Edit may accept a previously issued JWT with a live local session until expiry including leeway. The ADR assumes 300 seconds plus 30 seconds. The Edit verifier checks the signed times and allows 30 seconds of skew. Its claim checks impose no independent 300-second maximum on the difference between expiry and issuance. | Actual maximum lifetime issued to Edit, including after refresh, and the provider's cutoff for refresh and code exchange.                                            |
| Account deletion, suspension, password change or permission removal at the authority | The request authenticator consults Edit-local state. Publishing management currently stops at a service-unavailable response pending its external authorization contract.                                                                                                                                                       | For each event, establish the scope and timing of grant revocation, privilege removal and Edit notification. Include API keys if the authority actually issues them. |

Sources for the table include
[writer-side authentication](../../app/services/rp_request_authenticator.rb#L45),
[refresh installation](../../app/operations/rp_refresh_committer.rb#L90),
[back-channel receiver](../../app/controllers/concerns/rp_backchannel_logout_endpoint.rb#L27),
[transactional revocation](../../app/operations/rp_cell_session_revoker.rb#L32),
[callback tombstone check](../../app/operations/rp_callback_committer.rb#L49),
[residual acceptance contract](../../adr/first-party-sign-out-op-commit-and-backchannel-logout-for-separated-rp-stores.md#L75),
[JWT claim checks](../../app/adapters/oidc_op_access_token_verifier.rb#L91) and
[publishing gate](../../app/controllers/concerns/publishing_authority_api_endpoint.rb#L23).

## Decision and closure evidence

- Decide how a browser with a live, renewable Edit session should end it after access expiry.
  Identify the evidence that binds the stop to that browser and session, including when one cookie
  is missing. Keep CSRF protection and the local commit before success. Verify the transition across
  access expiry and confirm the resulting local row, cookie state and ability to renew. The existing
  success-case test provides a baseline.
  [Edit logout test](../../test/integration/oidc_rp_logout_registered_rp_matrix_test.rb#L13).
- Record the provider's actual issuance and event-delivery guarantees for the table above. Compare
  the documented maximum with the observed configuration, and decide who enforces the bound when a
  provider issues an unusually long-lived JWT.
- Reconcile previous entries by event and owner. The historical suspension/restore case concerns
  root credentials, the cancelled-logout entry concerns the OP grant, and the development delivery
  entry concerns verification of the back channel. Each needs its own evidence.
  [Operator restore](2026-10-22-pre-stop-jwt-accepted-after-operator-restore.md),
  [cancelled OP logout](2026-10-26-rp-grant-alive-after-cancelled-op-logout.md),
  [development logout delivery](2026-10-27-backchannel-logout-unverifiable-in-development.md).

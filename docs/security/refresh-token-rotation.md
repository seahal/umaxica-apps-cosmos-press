# OIDC Refresh at the Edit RP

As of the Press surface hard reset on 2026-11-10, this repository does not host an OIDC token
endpoint or issue and rotate provider refresh tokens. Edit ORG is the only retained browser RP. It
uses the configured external OIDC provider for authorization-code exchange and refresh; provider
token-family policy is owned by that provider and is not asserted here.

## Local refresh behavior

`RpRefreshCommitter` reserves the current installed generation under the local session and provider
binding locks, releases those locks before HTTPS, dispatches one refresh request through
`OidcOpTokenClient`, verifies the returned access token, then reacquires the locks before installing
the new generation. A concurrent revoke or newer installed generation prevents installation.

The RP does not resend a request whose outcome is indeterminate because the provider may have
rotated the presented credential. It clears the browser credentials and recovers through a new
authorization-code flow. A transport dependency failure keeps the existing credentials for retry; a
definitive provider refusal clears them. These decisions do not claim what the external provider
does with its refresh-token family.

## Related implementation

- `app/operations/rp_refresh_committer.rb`
- `app/adapters/oidc_op_token_client.rb`
- `app/controllers/concerns/browser_rp_authentication.rb`
- `app/controllers/concerns/oidc_callback.rb`
- `docs/identity/authority-boundary.md`

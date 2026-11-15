# Development Environment Setup

Status: draft. Sections marked "To be written" are placeholders for content that has not been
verified yet.

This guide collects, in order, every step a fresh clone needs before the application runs locally,
other than database preparation and seeding. Each step links to the document that owns the details;
this guide records only the order and the cross-cutting notes.

## 1. Host prerequisites

Install Podman, podman-compose, direnv, and mise. Run `mise install` from the checkout.

## 2. Material that is not in git

Obtain and place the items listed in
[development-credential-provisioning.md](development-credential-provisioning.md):

- `config/credentials/development.key` and `config/credentials/test.key`, from the development lead.
  Never generate them with `bin/rails credentials:edit`.
- The optional repository-root `.envrc.credential` for local credentials and machine-specific
  overrides. Enable the direnv shell hook and approve the reviewed `.envrc` before starting local
  services.

## 3. Local access

Run the development services on loopback.

## 4. Start the development services

Follow the [repository setup](../../README.md) to start Compose and run Rails on the host.

## 5. Databases

Database creation, migration, and seeding are covered by [db-workflow.md](db-workflow.md) and
[test-environment.md](test-environment.md). They are out of scope for this guide.

## 6. Local AWS substitute

To be written: when [local-aws-fakecloud.md](local-aws-fakecloud.md) is required for local work.

## 7. External sign-in providers

All provider credentials are read from Rails encrypted credentials in
`config/initializers/omniauth.rb`. Store them with
`bin/rails credentials:edit --environment development` only after the correct `development.key` is
in place. Never put a provider secret in a tracked file, a plan, or a note.

### 7.1 Microsoft Entra ID (Org surface)

Credential keys: `OMNI_AUTH_ENTRA_ORG_TENANT_ID`, `OMNI_AUTH_ENTRA_ORG_CLIENT_ID`,
`OMNI_AUTH_ENTRA_ORG_CLIENT_SECRET`.

Callback: `https://<org-auth-host>/social/entra/callback`.

The production-oriented procedure is [entra-org-login.md](../runbooks/entra-org-login.md).

To be written: the development-specific procedure (application registration, development callback
host, operator provisioning, and how to confirm a successful sign-in locally).

### 7.2 Google

Credential keys: `OMNI_AUTH_GOOGLE_APP_CLIENT_ID`, `OMNI_AUTH_GOOGLE_APP_CLIENT_SECRET`.

Callback: `https://<app-auth-host>/social/google/callback`.

To be written: Google Cloud Console project, OAuth consent screen, OAuth client creation, and
redirect URI registration.

### 7.3 Apple

Credential keys: `OMNI_AUTH_APPLE_CLIENT_ID`, `OMNI_AUTH_APPLE_TEAM_ID`, `OMNI_AUTH_APPLE_KEY_ID`,
`OMNI_AUTH_APPLE_PRIVATE_KEY`.

Callback: `https://<app-auth-host>/social/apple/callback`. It must be HTTPS on a real domain; a
`localhost` or IP address callback is not accepted.

Portal key management is in [apple-second-key.md](../runbooks/apple-second-key.md).

To be written: Services ID, Return URL, and `.p8` key setup for development.

## 8. Other external services

To be written: Cloudflare Turnstile ([../security/turnstile.md](../security/turnstile.md)), passkeys
([passkey.md](../runbooks/passkey.md)), and any other service that needs per-environment
configuration.

## 9. Verify the environment

To be written: the smallest set of checks that confirm a working setup.

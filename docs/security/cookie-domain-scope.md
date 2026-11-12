# Cookie Domain Scope

This repository owns Edit's relying-party cookies and the Preference cookies used by its current
Edit request lifecycle. Auth and Visa are external providers; their cookies are owned by those
provider hosts and are not issued or read by Press.

## Edit RP credentials

Edit stores its external OIDC credentials in the host-only RP cookie slots:

| Role                    | Production name     | Development name |
| ----------------------- | ------------------- | ---------------- |
| Access                  | `__Host-rp-access`  | `rp-access`      |
| Refresh                 | `__Host-rp-refresh` | `rp-refresh`     |
| Local RP session handle | `__Host-rp-session` | `rp-session`     |

The cookies use `Path=/`, `HttpOnly`, and `SameSite=Lax`; they do not set `Domain`. Secure contexts
use the `__Host-` prefix and `Secure`. Expiries for access and refresh cookies come from the OIDC
token response. The opaque RP session cookie expires with its local RP session. The implementation
is in `OidcRpBrowserCredentialContract` and `OidcRpCookieName`.

## Preference cookies

The Edit request lifecycle also consumes the Preference projection and display mirrors:

| Role                         | Cookie                      | Scope                                                          |
| ---------------------------- | --------------------------- | -------------------------------------------------------------- |
| Signed Preference projection | `__Secure-preference`       | Domain-scoped by the current request host                      |
| Language display mirror      | `language`                  | Domain-scoped by the current request host; JavaScript-readable |
| Experience display mirror    | `__Secure-experience`       | Domain-scoped by the current request host; JavaScript-readable |
| Browser binding              | `__Host-preference_binding` | Host-only and `HttpOnly`                                       |

The projection and display mirrors use `Path=/`, `Secure`, and `SameSite=Lax`. The projection is
`HttpOnly`; the display mirrors are not. The binding cookie uses `Path=/`, `Secure`, and `HttpOnly`.
`PreferenceWriteBoundary` derives the optional domain from the request host and leaves single-label
localhost hosts host-only. The signed projection alone does not authorize consent or Web Push reads;
the host-only binding is required.

These display cookies carry no session IDs, OIDC access or refresh tokens, grants, ceremony secrets,
or authorization data. Request context such as `ri` remains in the URL.

## Provider boundaries

An Auth or Visa origin is not a Press host. The browser keeps provider cookies under the provider's
host rules; Edit uses its own RP cookie slots on the Edit host. Press does not copy provider cookies
into its own cookie domain or treat a provider cookie as an Edit session.

## Related

- `adr/cookie-domain-scope-by-surface.md` — historical cross-surface decision; current local cookie
  behavior is described above.
- `docs/reference/subdomains.md`

# HTTP Cache Policy for Rails Controllers

This is the implementation reference for `Cache-Control` on the Press application surfaces. The
decision and its reasoning are in
[`adr/global-and-publishing-default-no-store-policy.md`](../../adr/global-and-publishing-default-no-store-policy.md).
Static and fingerprinted assets served by Propshaft or Vite are outside this policy.

## Policy by owner

| Surface                   | Default         | Cache opt-in                 |
| ------------------------- | --------------- | ---------------------------- |
| Edit ORG                  | `no-store`      | Action-local explicit opt-in |
| Docs, Help, Info and News | `no-store`      | Action-local explicit opt-in |
| Operator tools            | Engine-specific | Tool configuration           |

Every in-scope controller root declares `DefaultNoStore` and prepends `apply_default_no_store`.
Subclasses inherit it. An action that needs caching opts in with `fresh_when`, `stale?`,
`expires_in`, `expires_now`, or `http_cache_forever`.

Typical shapes:

```ruby
# Shared-cacheable public content, revalidated by a validator.
fresh_when(weak_etag: record.cache_key_with_version, last_modified: record.updated_at, public: true)

# Freshness lifetime.
expires_in 5.minutes, public: true

# Browser-private revalidation for an API representation.
fresh_when(weak_etag: payload, cache_control: { no_cache: true, extras: ["private"] })
```

`skip_before_action :apply_default_no_store` is forbidden. New code does not opt into caching by
writing `Cache-Control` headers directly; Rails merges such headers with the default, and `no-store`
wins. A response that varies by signed-in subject never opts into `public`.

Read-only Publishing entries use `ETag` and `Last-Modified`, answer conditional requests with `304`,
and carry a public `max-age`. Their cacheability is an action-level opt-in.

## Current roots

The public Docs, Help, Info and News controller roots are their `app`, `com` and `org`
`BareController` classes. Edit uses `Edit::Org::ApplicationController` and
`Edit::Org::BareController`. Their roots include `DefaultNoStore`; the Edit Publishing API and OIDC
logout receiver also set it explicitly at their own root.

The local Auth, Base, Core, Palm, Tech, Visa and Warp controller roots were retired on 2026-11-10.
Older inventories of those roots are historical and do not describe routes served by this checkout.
Mounted operator tools have their own authentication and cache behavior.

## Explicit no-store responses

Health and revision responses, machine JSON negotiation, Edit OIDC callback and sign entry,
jump-return verification, Edit sign-out completion, OIDC back-channel logout, and authenticated Edit
responses set `no-store` directly or inherit the surface default. Operator tool engines retain their
own response policy.

`test/security/invariants/default_no_store_policy_invariant_test.rb` enforces the root declarations,
callback order, and prohibition on skipping the default.

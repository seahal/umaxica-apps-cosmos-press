# Explicit request claims at the domain-policy boundary

- Commit: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`.
- Results include the substantial existing dirty worktree and this unit's policy/controller/test
  changes, not the commit alone.
- Scope: retained Edit authorization context, domain-policy fail-closed behavior, anonymous
  admission separation, and affected tests/static guards. No schema, CI, JWT-verifier, or
  session-lifecycle changes.

## Finding and contract

`ApplicationPolicy` still obtained token claims from global `Actor.authz` after Edit stopped
installing that lifecycle. A missing global value could select the legacy Normal capability context
instead of the current request's explicit context. No exploitable unknown-JWT authentication bypass
was demonstrated: the existing access-token verifier already rejects unsupported `authn_ctx` values.
That verifier remains unchanged.

Domain policies now receive both their explicit principal and `access_token_claims`. Edit binds
claims through a fixed private controller getter to the payload of its valid Browser RP access
state. Missing/malformed claims and unknown context values deny domain permission. An explicitly
supplied legacy policy payload without the claim retains the existing Normal interpretation; this
does not relax the browser verifier's required claims.

A blank principal denies domain permission even when an upstream result says `ok` and claims say
Normal. Concrete policies retain their own ownership/type/authority checks. Global Actor fallback
and compatibility actor/resource derivation were removed.

`Authentication::AccessPolicy` now directly owns the three unchanged anonymous/request-admission
predicates on `ActionPolicy::Base`, with optional user context. Anonymous admission does not inherit
a signed-session capability requirement. The forbidden-pattern scanner remains active; its obsolete
ApplicationPolicy raw-Actor-claims exception was removed.

## TDD observations

All Rails test commands used the six retained names in `POSTGRESQL_TEST_PREPARE_DATABASES` and
`PARALLEL_WORKERS=1`.

1. `test/policies/application_policy_actor_context_test.rb`: **6 runs, 8 assertions, 2 failures,
   zero errors/skips** before the policy fix. The missing-context case and interleaved unknown
   context incorrectly received ambient Normal behavior. The malformed-context partitions are
   exercised by the same test after the fix.
2. After the policy contract changed but before controller claims were wired, the policy plus actual
   HTTP tests produced **8 runs, 22 assertions, 1 failure, zero errors/skips**. A legitimate Normal
   dashboard request returned 403 instead of 200, demonstrating the missing request-to-policy
   binding.
3. The explicit-principal contract produced **8 runs, 18 assertions, 1 failure, zero errors/skips**
   before its fix: an upstream successful result allowed domain permission with no principal.
4. Final affected regression: **102 runs, 541 assertions, zero failures/errors/skips**.

The final command covered `test/policies`, authentication-context operation inventory, ActionPolicy
wiring, forbidden-pattern and controller-lifecycle invariants, actual Edit request-context
isolation, Browser RP authentication, local-session readiness, logout return, and OIDC
callback/region tests.

Coverage includes independently signed Normal/Standby access credentials reaching their own pages,
an unsupported signed context retaining its existing 401/cookie-clear behavior without a refresh
credential, interleaved independent browsers, and concurrent policy instances with separate
Normal/unknown/Standby contexts. Anonymous Sign rendering and protected-page admission also pass.
Existing PKCE/state/nonce/browser binding, refresh/CSRF ordering, revocation, and dependency-cookie
behavior remain covered by the affected regression.

## Review and limits

The concrete risks reviewed were stale authority across requests, cross-principal policy use,
missing prerequisites defaulting open, and admission checks accidentally inheriting domain
requirements. Tests exercise public policy/request interfaces; no production test branch, Actor
lifecycle restoration, authentication-check relaxation, or new role permission was introduced.

The concurrency check evaluates policy instances in parallel; HTTP browser requests are interleaved,
not a parallel server load test. Repository-wide final validation is reported separately from this
affected regression.

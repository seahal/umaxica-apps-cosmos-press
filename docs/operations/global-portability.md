# Global portability contract

This document is the operational contract for the Global repository. It keeps application settings
portable while leaving Compose responsible for infrastructure topology only.

## 1. Repository scope

This repository remains the Global application. Regional responsibilities are not split here and no
Regional repository is created by this work.

## 8. Valkey

Cache and rate-limit stores remain physically separate. Host mode uses ports 6379 and 6380; the
container contract uses the two Compose service names. Neither store is a correctness datastore.

## 9. Object storage

FakeCloud is a disposable local S3-compatible endpoint on loopback for host tools and the
`fakecloud` service name for the container. Local access-key values are visibly fake test values.

## 10. Host exposure

Every published development port remains explicitly loopback-only. PostgreSQL and Valkey are not
reachable from the LAN, and no service uses host networking.

## 12. Frontend toolchain

Bun is the sole package manager and script runner. Vite, Vitest, Playwright, TypeScript, and the two
Rails frontend stacks remain intact. The package manager is pinned in `package.json` and the image.

## 15. Database lifecycle

Local database, queue, cache, replica, and FakeCloud volumes are disposable. Destructive recreation
is acceptable during local recovery; never apply that procedure to a production volume.

## 16. Portability failure mode

Missing required values fail loudly through `ENV.fetch` or the existing typed configuration values.
The loader only fills absent local development values and never replaces explicit process settings.

## 17. URL contract

Private localhost aliases are used for direct local requests. Public URL values remain explicit and
are not inferred from a Compose project name or container hostname.

## 19. CI contract

CI installs Bun from the pinned setup action, installs from `bun.lock`, runs Bun scripts, and leaves
Rails database setup and tests explicit. The local CI helper follows the same commands.

## 21. Security review

The change does not alter cookie, session, authentication, authorization, CSRF, WebAuthn, OIDC, or
provider policy. It changes only how non-secret local configuration reaches the existing app.

## 22. Handoff decision

Regional cloning is not a task performed by this repository. The final evidence reports whether the
Global application is ready for that future clone and names any concrete verification blocker.

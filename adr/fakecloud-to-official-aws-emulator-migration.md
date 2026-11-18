# Replace FakeCloud with the Official AWS Emulator (2026-11-16)

## Status

Accepted (2026-11-16). Direction only; the migration has not started. Until it does, the FakeCloud
service in `compose.yaml` and the decisions in `adr/fakecloud-podman-staging-environment.md` stay in
force.

## Context

All four Cosmos repositories (Access, Governance, Press, Sphere) emulate AWS locally with FakeCloud
(`ghcr.io/faiscadev/fakecloud`, digest-pinned, run by Podman Compose on `127.0.0.1:4566`).
`adr/fakecloud-podman-staging-environment.md` also makes FakeCloud the AWS emulator for staging.

FakeCloud is a third-party project. The owner has decided that local development and staging should
emulate AWS with the emulator AWS itself provides, instead of a third-party one.

## Decision

1. **FakeCloud is to be retired.** Access, Governance, Press and Sphere must each migrate from
   FakeCloud to the official AWS emulator. No repository keeps FakeCloud after its migration.
2. **The migration target is AWS's own emulator**, not another third-party emulator. Which AWS
   product that is, and which of the services used today (object storage, streaming, KMS signing) it
   covers, is confirmed when the migration starts and recorded then.
3. **Nothing is implemented by this record.** `compose.yaml`,
   `terraform/environments/*/providers.tf`, `lib/object_storage_shrine_configuration.rb` and the
   documentation are unchanged.
4. **The constraints of `adr/fakecloud-podman-staging-environment.md` that are not specific to
   FakeCloud carry over**: environment-agnostic `terraform/modules/`, emulator specifics only in
   `terraform/environments/<env>/`, separate staging bucket names, the `OBJECT_STORAGE_*` variable
   namespace, and visibly fake credentials.

## Consequences

- `adr/fakecloud-podman-staging-environment.md` is superseded in its FakeCloud-specific parts once
  the migration lands; until then it remains authoritative.
- Coverage gaps already recorded for FakeCloud (RDS/Aurora in
  `adr/staging-aurora-postgresql-topology.md`, KMS signing in Access's
  `adr/cosmos-signing-key-management.md`) are re-checked against the official emulator.
- Access's `adr/cosmos-development-on-vms-with-local-tls.md` removes Compose from development; how
  the official emulator is run after that move is decided together with this migration.

## Open questions

- The exact official AWS emulator product, its licensing, and its service coverage.
- Whether all four repositories migrate together or one at a time.

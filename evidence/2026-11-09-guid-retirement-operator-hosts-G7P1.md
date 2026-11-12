# GUID retirement and Press operator hosts

- Date: 2026-11-09; HEAD `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`.
- Accepted scope: the user's GUID retirement and repository-specific operator-host instructions,
  based on `specs/cosmos-press-route-ownership/spec.md`.
- Uncommitted changes affected every check. Existing unrelated changes were preserved; the earlier
  Rails pin remains. No commit, external service change, database reset or development database
  creation was performed.
- This slice does not implement the spec's other surface removals, publishing API move, or Edit
  sign-in migration. The spec remains implementing.

## Changes

- Removed GUID route drawing and route file, 11 controllers, standalone view, stylesheet and two
  dedicated positive test files. Retained the five Edit no-store cases in their renamed file.
- Removed GUID-only boot host fields, availability registry entry, health profile, runtime-role
  family and host admission entries. Reconciled affected mixed tests, tooling path baselines and
  current documentation.
- Preserved `PublicId`, blind-index/encryption services, existing issued identifiers, WebAuthn
  AAGUID processing, logging filter classifications, shared concerns and all persisted data. The
  removed resource controller only validated transport input and returned 404; it did not own
  identifier generation or resolution used by retained code.
- Added refusal coverage for both former GUID hosts across their former GET endpoints and CSP POST.
- Retained all seven operator route mounts and origin authentication. Updated their public values in
  `.env.container.devcontainer` to `<tool>-press.umaxica.dev`, plus route/initializer comments and
  current UI inventory. Private names remain unchanged. Development host admission already reads all
  seven public environment keys.
- The Access repository was unavailable in the mounted filesystem. The accepted Press spec and
  tunnel plan provide the exact Access-derived naming pattern used here.

## Verification

- Full pre-retirement baseline: 17,164 runs, 149,566 assertions, 304 failures, 67 errors, 0 skips;
  see `2026-11-09-rails-revision-pin-R9P1.md`. This completed before code changes in this slice.
- Scoped Rails run covered 16 files: controller inheritance, no-store policy/Edit, layout titles,
  public entrypoint and RI guards, boot host values, provider host matrix, OpenAPI coverage,
  runtime-role ownership/guard, FQDN registry/gate, PublicId generation, blind indexes and retired
  hosts. Completed with **120 runs, 4,253 assertions, 3 failures, 0 errors, 0 skips**.
- All three failures also occurred in the full baseline and were left unchanged:
  - `OpenapiRouteCoverageTest#test_no_route_the_router_serves_is_missing_from_its_surface_description`:
    `Minitest::Assertion`, `test/contracts/openapi_route_coverage_test.rb:61`; existing missing app
    OpenAPI operations.
  - `LayoutTitleContractTest#test_no_layout_or_view_builds_a_title_outside_meta-tags_except_the_standalone_documents`:
    `Minitest::Assertion`, `test/integration/layout_title_contract_test.rb:81`; two retained
    Auth/Visa views.
  - `XperRetiredHostsTest#test_a_retained_Base_host_still_owns_the_same_endpoint_paths`:
    `Minitest::Assertion`, `test/integration/xper_retired_hosts_test.rb:77`; existing region
    redirect.
- The new GUID refusal case and retained identifier/guard cases passed. Scoped failure inventory:
  `/tmp/press-rails-pin-R9P1/guid-retirement-test-failures.md`; output:
  `/tmp/press-rails-pin-R9P1/guid-retirement-tests-ready.log`.
- `RAILS_ENV=test bin/rails runner` printed `8.2.0.alpha` and confirmed that no route controller
  starts with `guid/`.
- Targeted RuboCop across changed surviving Ruby files, including Gemfile and the new refusal
  coverage: no offenses. `git diff --check`: passed.
- `bun run check`: passed after `bun install --frozen-lockfile`. No package manifest or Bun lockfile
  changes resulted. The install ran the existing Lefthook install hook.
- Initial frontend check lacked `oxfmt`. The first scoped Rails attempt entered a recursive
  Vite/binstub invocation before JS dependencies were installed; that process tree was stopped,
  dependencies installed, and verification rerun successfully as described above. No tests were
  reported as executed by that aborted attempt.

## Runtime observations and remaining blockers

- Started a development Rails server on `127.0.0.1:49183`, explicitly supplying the seven new public
  host variables because inherited exports and the ignored `.env` still carry old values. The
  verification server was stopped afterwards.
- For every tool (`mission`, `flipper`, `blazer`, `pghero`, `swagger`, `performance`, `coverband`),
  the new public and preserved private host passed HostAuthorization but returned 500 before
  dashboard authentication: `ActiveRecord::NoDatabaseError`, missing `development_publishing_db`;
  first repository frame `config/initializers/schema_migration_if_not_exists.rb:10`.
- Every old unsuffixed public tool host returned 403. Host-probe status inventory:
  `/tmp/press-rails-pin-R9P1/operator-host-probes.txt`.
- Unauthenticated 401 and authenticated dashboard access remain unverified due to the missing
  development database. No development database was created; that needs explicit authorization.
  Existing Basic authentication code was preserved without edits to its behavior or credentials.
- `.devcontainer` and `.github` are separate read-only mounts (`findmnt` reports `ro`). Writes
  failed with `OSError: [Errno 30] Read-only file system`. Remaining exact patches were prepared
  outside the repository without bypassing those mounts:
  - `/tmp/press-rails-pin-R9P1/devcontainer-operator-hosts.patch`: replace seven public aliases and
    remove two GUID aliases in `.devcontainer/compose.yaml`; preserves its existing unrelated edits.
  - `/tmp/press-rails-pin-R9P1/ci-guid-retirement.patch`: remove the two obsolete GUID URL inputs
    from `.github/workflows/ci.yml`.
- Container aliases are therefore not yet updated, and containers were not recreated. Apply those
  patches from a writable host checkout and recreate the affected container before DNS validation.
  Session-local `/tmp` artifacts may not survive executor cleanup.
- Full ownership-spec acceptance remains open. No claim is made about deployed Cloudflare DNS,
  Access applications, tunnel ingress or authenticated dashboard availability.

## Follow-up while checking remaining tasks

- Updated the ignored local `.env` values for all seven public operator hosts and removed its two
  retired GUID URL entries. Secret values and unrelated local settings were left intact.
- Updated current Gemfile and Redocly comments to name Press's Swagger and performance hosts.
- Rebuilt `/tmp/press-rails-pin-R9P1/ci-guid-retirement.patch` to update the seven old operator host
  values in both CI job environments and remove both stale GUID entries. The Dev Container patch
  remains at `/tmp/press-rails-pin-R9P1/devcontainer-operator-hosts.patch`.
- The two exact files remain on read-only mounts, so neither patch can be applied in this executor.
  The repo-wide reference scan shows old hostnames only in those two read-only files, plus
  historical plans/evidence and Git's lost-found objects. Historical records were preserved.
- During a local configuration check, a command printed part of the ignored `.env` to tool output,
  including Cloudflare and Neon credentials. Values are intentionally omitted from this record. The
  user was notified to treat them as disclosed and rotate them. No credential was sent to an
  external service or repeated in chat.

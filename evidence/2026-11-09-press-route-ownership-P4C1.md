# Press route ownership and Rails verification

- Date: 2026-11-09.
- Repository: Cosmos Press.
- HEAD: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`.
- Verification used this uncommitted worktree. It was not clean before this task; pre-existing
  changes were preserved. No commit or remote write was made.
- Scope follows `specs/cosmos-press-route-ownership/spec.md` and the user's clarification: Press
  retains Info, Docs, Help, News, Edit and seven operator tools; it removes non-owned route
  families. Access, Governance and Sphere retain other surfaces except the content, Edit and GUID
  removals named in the spec/order. Preference placement remains open; Edit's Base Preferences link
  is gone.

## Changes

- Press draws only Info, News, Help, Docs, Edit and the seven operator tools. Removed the other
  surface route files and their controller, view and route-specific test trees.
- Moved the Base organization publishing API into Edit's `/api/v0/publishing/...` route and
  controller namespace. Updated its runtime-role owner, client URL, route contracts and tests.
- Removed the Edit layout link to Base preferences. Preserved shared identifier handling and the
  existing OIDC client registrations.
- Set all seven Press tool routes, FQDN reservations and development/production Host Authorization
  entries to `*-press.umaxica.dev`. The route constraints use canonical host literals and private
  development aliases; they no longer rely on old `PUBLIC_*_URL` tool values.
- Updated controller inheritance, no-store and authorization inventories to the remaining Press
  surfaces. Removed stale tests that directly required deleted controller classes.
- The host values in `.github/workflows/ci.yml` and `.devcontainer/compose.yaml` are still the old
  unqualified values. A write to the Press CI file failed with `Read-only file system`; the host
  aliases therefore remain a deployment/dev-container blocker.

## Verification

- `RAILS_ENV=test bin/rails runner 'puts Rails.version'`: passed; printed `8.2.0.alpha`.
- `getent hosts primary`: passed in the Press development container; the full test run also reached
  the configured test databases. No development database, database volume, or external service was
  created, reset or deleted.
- `bin/rails test`: completed with **15,169 runs, 97,970 assertions, 787 failures, 1,215 errors, 0
  skips**. The full failure/error index, with exception type, test name and first repository line,
  is saved outside the repository at `/tmp/2026-11-09-press-route-ownership-test-failures.txt`.
- `bin/rubocop Gemfile` plus the changed Ruby files: 46 files inspected, no offenses.
- `git diff --check`: passed.
- Ruby syntax checks for the changed Press development/production host configuration and FQDN
  registry passed.
- Access, Governance and Sphere source changes have separate repository evidence. Their Rails suites
  could not run in their sparse checkouts; their recorded Ruby/YAML/static checks passed.

## Remaining blockers

- AC-4 remains unverified end to end. `test/integration/edit_org_jump_rt_sign_in_test.rb` verifies
  that Edit starts the OIDC admission on `visa.umaxica.org`, but it does not complete the Visa/Auth
  callback into Edit. The Access checkout has no Rails runtime, and the Press CI/Compose host values
  still do not match the canonical tool hosts.
- Retained Edit publishing writes can reach the new route, but the new Edit verification endpoint
  currently fails closed. The full suite includes publishing tests that receive HTTP 503 before the
  expected validation response. Edit has no local step-up cell/registered state, and implementing
  one would require an authentication/verification ownership decision. The protection was not
  bypassed; the design decision remains open.
- Press CI and container aliases could not be updated while those files are read-only. Until the
  worktree is writable and those exact files are aligned, the requested public tool hosts are not
  connected to the Press development container/CI environment.
- The full suite completes, but its failures include many remaining tests that still exercise
  deliberately removed Auth/Base/Core/Visa/Palm/Warp/Tech routes, alongside other errors. The saved
  index is the complete result; those cases have not been represented as passing or pre-existing.
- `.env*` files were not read or edited. Test credentials and database settings were not changed.

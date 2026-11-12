# Press identifier HMAC credentials rotation

Date: 2026-11-10. Revision: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`. The worktree was extensively
dirty before this work. Verification includes the uncommitted changes listed below and the existing
unrelated worktree; it does not establish a clean-HEAD result. No commit was made. No development
database was deleted, reset or schema-migrated.

## Authorization and scope

The owner requested fresh repository-specific APP/ORG email and telephone lookup HMAC keys in
development/test credentials, environment assignment removal, tests and development verification.
The owner separately approved the development backfill in this session and confirmed identifier
writes were stopped. After the read-only filesystem blocker was reported, the owner explicitly chose
to handle CI assignment removal later.

## Inventory and credential changes

Names only: `APP_EMAIL_ADDRESS_HMAC_KEY`, `ORG_EMAIL_ADDRESS_HMAC_KEY`,
`APP_TELEPHONE_NUMBER_HMAC_KEY`, `ORG_TELEPHONE_NUMBER_HMAC_KEY`.

- Found four assignments in ignored `.env`, four in `.env.container.devcontainer`, and eight in
  `.github/workflows/ci.yml` (four in each of two jobs). The Dev Container loads the container
  environment file; `LocalEnvironment` also loads the root `.env`. No direct assignments were found
  in root Compose files or Dev Container YAML.
- Generated eight independent values with `SecureRandom.hex(32)` in this repository, four per
  environment, and wrote them using `ActiveSupport::EncryptedFile` to
  `config/credentials/{development,test}.yml.enc`. Other credential entries were compared in memory
  and preserved. No other repository's values were accessed or reused.
- Decrypted verification confirmed all eight values are distinct 64-character hexadecimal strings
  and none equals any inherited target ENV value. No secret values or fingerprints were output or
  recorded. One initial Ruby command had a syntax error before executing; the corrected command
  performed the writes and verified them.
- Removed all four assignments from `.env` and `.env.container.devcontainer`; final name-only checks
  found zero remaining assignments in each file.
- CI removal failed with `Errno 30: Read-only file system`, including with approved escalation.
  Eight assignments remain in `.github/workflows/ci.yml`; owner deferred removal. No CI file
  changed.
- Existing process/container environments still inherit the four old names. They cannot be modified
  in their parent by this session; application lookup code no longer reads them, and the
  verification server and backfill were launched with all four explicitly unset. Recreate the usual
  development processes/container to discard inherited settings.

## Runtime source correction

Inspection of the pinned Rails implementation found `Rails.app.creds` combines ENV before encrypted
credentials, plus dotenv in development. Removing the explicit ENV fallback alone was insufficient.
The final implementation uses `Rails.app.credentials.option` directly and rejects missing/blank
values. The history verifier compares live keys against that same encrypted source; its separate
history keys are outside this four-key scope.

The initial development comparison using the combined API reported zero mismatches; it was not valid
evidence of using the new keys. After the direct-source correction, there was one stale APP email
and one stale ORG email, as expected. A separate in-memory comparison confirmed the four runtime
values match the newly written development encrypted file.

Updated source: `app/lib/identifier_blind_index.rb` and
`app/lib/identifier_history_fingerprint_verifier.rb`. Updated credential-boundary/rotation/history
tests under `test/lib/` and `test/services/realm_identifier_hmac_rotation_test.rb` use credential
stubs rather than relying on ENV values. All four missing, empty and whitespace credential cases are
refused even when scoped and legacy ENV values exist. Existing success/normalization and
realm/channel isolation coverage remains.

The owner backlog records the combined-API clarification; the contact-identifier checklist and
development credential documentation record the resulting contract. The executable procedure is
`docs/runbooks/development-identifier-blind-index-backfill.md`.

## Verification

- `bundle check`: dependencies satisfied; Ruby `4.0.9`, Bundler `4.0.24`.
- Initial sandboxed Rails tests could not resolve `primary`. Repeating with approved network
  escalation succeeded. Final affected collection:
  `bin/rails test test/lib/identifier_blind_index_test.rb test/lib/realm_identifier_digest_test.rb test/lib/identifier_history_fingerprint_verifier_test.rb test/services/realm_identifier_hmac_rotation_test.rb test/services/identifier_blind_index_backfill_test.rb`:
  **60 runs, 505 assertions, zero failures/errors/skips**.
- Final `bin/rails test test/security`: **114 runs, 598 assertions, zero failures/errors/skips**.
- `bin/rubocop` on the two changed Ruby source files and four changed test files: **six files, no
  offenses**. Initial style findings were corrected before the final runs.
- Scoped `git diff --check`: passed. No full CI gate was run.
- Read-only development inventory: APP email 1, APP telephone 0, ORG email 1, ORG telephone 0;
  finalized APP identifiers 0; malformed identifiers 0. An initial diagnostic incorrectly queried
  the APP-only finalization column on ORG and failed read-only; the corrected inventory completed.
- After explicit owner approval and stopping the temporary verification server, executed
  `IdentifierBlindIndexBackfill.new.call` in development with all four target ENV names unset and
  Active Record query logging disabled. First result:
  `user_emails_updated=1, user_telephones_updated=0, staff_emails_updated=1, staff_telephones_updated=0`.
  Every stored digest matched its recalculated value. Existing APP/ORG addresses were obtained only
  in memory and `find_by_address` returned the same record IDs. Non-digest attributes except
  `updated_at` were compared in memory and preserved. Second invocation returned four zero counts.
- Development server launched before and after backfill with all four names unset,
  `RAILS_ENV=development PORT=3137 WEB_CONCURRENCY=0 PIDFILE=tmp/hmac-rotation/server.pid bin/rails server`.
  Puma listened on port 3137; `GET /health/startup` with Host `docs.app.localhost` returned **200**
  on both runs. Socket/network restrictions required approved escalation. Both temporary servers
  were stopped after verification.

## Limits and recovery

CI's eight assignment lines remain by owner deferral; the original request to remove all assignments
is therefore incomplete for CI. Broader secret inventory/rotation and other repositories were not
part of this task. No staging/production changes were made.

Email lookup was verified through the public model lookup API, including both existing records; a
complete browser sign-in/OTP flow was not exercised. The current Press route/controller tree
contains no local sign-in email endpoint, and no replacement route was introduced.

The backfill is not atomic across databases. Its approved recovery is to hold identifier writers,
keep the new keys, fix the cause and rerun idempotently from the encrypted readable identifiers.
Finalized APP rows require the existing restricted-maintenance procedure rather than bypassing
immutable-binding protections. No such rows were present in this run.

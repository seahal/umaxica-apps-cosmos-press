# Development Identifier Blind Index Backfill

## Scope and approval

This procedure recalculates APP/ORG email and telephone lookup digests after the four keys are
replaced in this repository's development credentials. It implements the owner decision in
[credentials-only secrets](../backlog/2026-11-10-secrets-from-credentials-only.md).

The owner must approve the development database write before the command below runs. Approval for
credential replacement alone does not authorize this backfill. Never delete or reset a database.
Never print identifiers, decrypted credentials, keys, lookup digests or connection URLs.

## Prerequisites

1. Stop identifier writes from development servers, workers and other operators for all four
   affected models. Keep writes stopped until verification completes: mixed key generations defeat
   logical uniqueness and old digests cannot be found using the new keys.
2. Confirm `RAILS_ENV=development`, the intended database targets and availability of the existing
   readable-identifier encryption keys. The four HMAC keys must exist in development credentials.
3. Read-only inventory: count `ClientEmail`, `ClientTelephone`, `OperatorEmail` and
   `OperatorTelephone`; count malformed identifiers and digests differing from their recalculated
   values. Report counts only. APP email/telephone records also have `binding_finalized_at`; do not
   query that column on ORG models.
4. If finalized APP rows need changes, stop. `IdentifierBlindIndexBackfill` uses ordinary model
   writes and cannot change their protected digests. Follow the separate restricted-maintenance
   procedure in [the HMAC rotation contract](../security/identifier-hmac-emergency-rotation.md)
   after obtaining scoped approval and access. Do not disable triggers or change privileges.
5. Confirm the owner's recovery arrangement and approval for these exact four models. Retain the new
   keys on failure; recovery is a forward retry from readable encrypted identifiers. If identifiers
   cannot be decrypted or normalized, stop for an owner decision.

## Execution after approval

There is no `identifier_blind_index_backfill` Rake task in this repository; the implementation is
`app/services/identifier_blind_index_backfill.rb`. In the configured Dev Container run:

```bash
RAILS_ENV=development bin/rails runner 'abort "development only" unless Rails.env.development?; ActiveRecord::Base.logger = nil; result = IdentifierBlindIndexBackfill.new.call; puts result.to_h'
```

Only the four updated-row counts are printed. The service visits APP email, APP telephone, ORG email
and ORG telephone in that order, in batches of 1,000. It is not one transaction across
models/databases. Failure may leave partial progress: keep writers stopped, report only a sanitized
error category, resolve the cause and rerun the same idempotent operation. Never restore a retired
HMAC key to hide a partial run.

## Verification and restart

- Recompute each row's expected digest in memory and compare without displaying identifiers or
  digests. All mismatch and malformed counts must be zero.
- A second service invocation must report zero updates for every model.
- Start the development Rails server, verify it listens and check email lookup through
  `ClientEmail.find_by_address` and `OperatorEmail.find_by_address`. For existing rows, obtain
  addresses in memory and compare returned record IDs as booleans without printing either.
- Verify the sign-in entry belongs to this repository before testing a browser endpoint. A synthetic
  nonexistent email exercises the query without sending mail or creating account state; it does not
  prove that existing identifiers have been backfilled.
- Record revision, dirty-worktree scope, counts, checks and remaining blockers in `evidence/`.

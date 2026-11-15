# CI static checks zero — secret scan correction

Date: 2026-11-13

This record supplements CSZ0 and CSZ1 after the current-tree secret findings were classified.

## Revision and worktree

- Full `HEAD`: `4ff0fb165ce782c6f621d7797438e278e114fd1e`.
- Hundreds of unrelated uncommitted changes remain. No commit, push, deployment, database change,
  credential edit or CI workflow edit was made.

## Gitleaks correction

- The 107 findings in `research/2026-10-22-test-value-audit/duplicates.md` were SHA-256 body
  digests, not credentials. Their annotation changed from “Body token hash” to “Body SHA-256
  digest”; digest values and audit rows are unchanged.
- The two findings in the archived authentication handoff log were full Git commit IDs following
  `HEAD:`. Those two references now use 12-character prefixes, each verified unique in repository
  history. Other archived references were left intact.
- Rebuilt a temporary snapshot from tracked and non-ignored project files and ran
  `gitleaks detect --no-git --source <snapshot> --redact --no-banner` — **5,170 files, exit 0, 0
  findings**, with no allow-list. The ordinary whole-history scan remains **247 committed-history
  findings**; no shared history rewrite was authorized.

## Remaining database-consistency result

- `gem list --remote --all '^database_consistency$'` confirms **3.1.2** is the newest released
  version available. The repository uses that release; no checker fork, configuration file,
  suppression or checker edit is present.
- `RAILS_ENV=test ... bundle exec database_consistency` still reports **24** `NullConstraintChecker`
  findings for `content_digest` on the 12 Publishing `EntryRevision` and 12 `EntryVersion` models.
- The released checker source accepts presence, inclusion, nil exclusion and non-nil numericality;
  it does not infer nil rejection from the existing create-scoped length/format validators. The
  model currently rejects a nil digest on creation with `wrong_length` and `invalid` validation
  errors. The accepted C10 record explicitly says not to add redundant presence or change these
  create/update failure contracts solely to remove the checker report. The database independently
  enforces NOT NULL and digest shape. No model, schema or test behavior was changed for these
  findings.
- The generic request to complete this work does not specify reversal of C10's recorded contract or
  authorize a change that the work order forbids. Therefore these 24 reports remain a concrete
  owner-decision blocker; the overall zero-finding objective is not met.

## Integrity

- `git diff --check` — pass.
- Database schemas and encrypted credential files remain unchanged. No checker suppression was
  introduced.

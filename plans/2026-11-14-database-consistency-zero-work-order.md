Task (umaxica-apps-cosmos-press only): bring `database_consistency` to zero findings.

## Observed on 2026-11-14 (RAILS_ENV=test, exit 1, 24 findings)

All 24 are `NullConstraintChecker`: `content_digest` is NOT NULL but has no validator disallowing
nil, on `Publishing::{News,Info}::{App,Com,Org}::Entry{Version,Revision}` (2 families × 3 realms × 2
models, each reported twice or per checker pass; confirm the exact count). The column is validated
in `app/models/concerns/publishing_encrypted_content.rb:23` with
`validates :content_digest, length: { is: 64 }, format: …, on: :create`; the `on: :create` scope is
the likely reason the checker does not count it. The last clean result was
`evidence/2026-11-12-keep-database-consistency-final-F5Z0.md`.

## Work

Decide whether `content_digest` may change after create (versions and revisions are normally
immutable: check the immutability rules already enforced). Make the validator state that the value
is always present and well-formed, in a shape the checker recognises, without allowing an update
path that the database or the immutability rules refuse. Cover nil, empty, 63/64/65 characters,
non-hex, and update attempts, for one representative cell per family and a static check that all
twelve cells include the concern.

No commit. Never print secrets, key material or environment values. Never edit
config/credentials/*.yml.enc. No push, no deploy, no Cloudflare change, no change outside this
repository. Do not disable a checker, add an exclusion or a todo file, or weaken a database
constraint to make the report pass; fix the model or the schema so both sides state the same
contract. Every schema change is a reversible migration. Tests Red first; no mocked behaviour under
test.

## Checks and report

`RAILS_ENV=test RUBY_DEBUG_ENABLE=0 bundle exec database_consistency` must exit 0 (record the
command and the finding count before and after). Then bin/rails zeitwerk:check, bin/rubocop,
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error, the changed and related tests,
bin/rails test (separate pre-existing failures; unset `POSTGRESQL_TEST_PREPARE_DATABASES` if its
stale list blocks boot and report it). Update docs/mermaid inventories and checklists if a lifecycle
or deletion rule changes.

Evidence: `evidence/YYYY-MM-DD-database-consistency-zero-XXXX.md` (full `git rev-parse HEAD`;
uncommitted changes affected results): each finding, its cause, the fix and its test, migrations,
results, owner items, and confirmation that config/credentials files are unchanged.

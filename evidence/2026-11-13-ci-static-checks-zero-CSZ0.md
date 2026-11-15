# CI static-check inventory and remediation

Date: 2026-11-13

## Revision and scope

- Full `HEAD`: `4ff0fb165ce782c6f621d7797438e278e114fd1e`.
- The checkout already contained substantial uncommitted work. At final inspection, `git status`
  reported 510 paths: 505 unstaged paths, 5 untracked paths and 0 staged paths. This record does not
  claim that all existing changes belong to this task. No commit or push was made.
- No files under `db/` changed. `git diff -- config/credentials` was empty.
  `.github/workflows/ci.yml` already had an unstaged host edit before this work; it was not edited
  here.
- The only Rails test database preparation override was process-local and limited to the six
  retained test databases. No shared or production database was dropped or changed.

## Work performed

1. Removed the local `vendor/fork/database_consistency` path dependency and restored its ignored
   checker source to the repository's released implementation. `Gemfile` now uses the RubyGems
   release, and `Gemfile.lock` resolves `database_consistency` 3.1.2. No checker configuration or
   exclusion file was added.
2. Removed `.rubocop_todo.yml` and its inheritance. Fixed the 470 architecture offenses it had
   hidden: 448 implicit public visibility declarations and 22 concern inclusion hooks. Explicit
   `configure` calls preserve the existing concern setup points. Safe autocorrection handled the
   remaining layout offenses; no unsafe autocorrection, `rubocop:disable`, or exclusion was added.
   The architecture measurement is now a non-suppressive per-file zero ratchet, with the current
   method visibility guidance updated accordingly.
3. Added the missing frozen-string directive to `config/importmap.rb`.
4. Updated the database-consistency checker test for the released checker's supported contract. It
   still asserts that positive-length validation rejects nil during creation; it now also asserts
   that the checker does not treat that validation as a presence proof.
5. Added a root `postcss-selector-parser` override at 6.1.5 to resolve the reported moderate
   advisory. `bun.lock` records the resolved dependency.
6. Restored `scripts/check-repository-knowledge`, which is called by `config/ci.rb` and documented
   by the open repository-knowledge spec but was absent from the checkout. The restored checker
   correctly rejects paths outside the repository. Its normal run exposes two pre-existing missing
   routed documents; neither the rules nor the checker was weakened to hide them.

No migrations, database constraints, application behavior, CI workflow, credentials, or test
database contents were changed.

## Checks and results

| Check                        | Command and result                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| RuboCop                      | `bundle exec rubocop --fail-level convention` — **1275 files, 0 offenses**. `bin/rubocop` also passed. Before removing the TODO file, the architecture cops reported 470 offenses (448 visibility, 22 inclusion hooks).                                                                                                                                                                                                             |
| Frozen-string checks         | `ruby scripts/check_frozen_string_literal_directives.rb` — **1348 files passed**. `bundle exec rubocop --config .rubocop_frozen_string_literal.yml --only Style/FrozenStringLiteralComment,Style/DisableCopsWithinSourceCodeDirective .` — **1349 files, 0 offenses**.                                                                                                                                                              |
| ERB-Lint                     | `bundle exec erb_lint --lint-all` — **855 files, 16 configured linters, 0 errors**, about 1.3 seconds. The Ruby parser emitted its existing Ruby 3.3 parser / Ruby 4.0 runtime compatibility warning.                                                                                                                                                                                                                               |
| i18n missing                 | `bundle exec i18n-tasks missing` — **0 missing translations**.                                                                                                                                                                                                                                                                                                                                                                      |
| i18n unused                  | `bundle exec i18n-tasks unused` — **1250 locale entries remain** (625 keys in each of `en` and `ja`; 625 distinct keys). See the owner-contract stop below.                                                                                                                                                                                                                                                                         |
| Brakeman                     | `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error` — **0 errors, 0 security warnings**. No Brakeman ignore file was added.                                                                                                                                                                                                                                                                                            |
| Secret scan                  | `gitleaks detect --source . --redact --no-banner`, with process-only Git textconv configuration so Rails credentials were not evaluated — scanned **3222 commits**, reported **247 findings** (245 `generic-api-key`, 2 `private-key`). All reported findings had committed origins; no uncommitted finding was reported. A separate no-Git full-tree scan did not complete and is not claimed as passing. No allow-list was added. |
| GitHub workflow syntax       | Official actionlint **1.7.12**, checksum-verified temporary binary: `actionlint .github/workflows/ci.yml` — **pass**. The pre-existing environment's 1.7.7 reported four `ubuntu-slim` runner-label errors; 1.7.12 recognizes those labels. The workflow itself was not edited.                                                                                                                                                     |
| Ruby dependency audit        | `bin/bundler-audit check --update` — **no vulnerabilities**; advisory database updated to the current available snapshot.                                                                                                                                                                                                                                                                                                           |
| JavaScript dependency audit  | `bun audit --audit-level=moderate` — **0 vulnerabilities across 159 packages** after the override. Before it, the nested parser dependency produced one moderate advisory.                                                                                                                                                                                                                                                          |
| JavaScript formatting        | `bun run format:check` first found only `package.json` formatting. `bun run format` corrected it; the final `bun run format:check` passed for all 12 matched files.                                                                                                                                                                                                                                                                 |
| JavaScript lint and types    | `bun run lint` and `bun run typecheck` — **pass**.                                                                                                                                                                                                                                                                                                                                                                                  |
| JavaScript aggregate check   | `bun run check` — **pass**, including formatting, lint, typecheck, OpenAPI lint and unchanged OpenAPI bundle verification.                                                                                                                                                                                                                                                                                                          |
| Production Vite build        | `bun x vite build --mode production --outDir /tmp/press-vite-build-20261113 --emptyOutDir` — **pass**, 2 modules transformed and the active Edit stylesheet emitted. The Ruby Vite plugin still wrote build output under ignored `public/vite`; generated output is not tracked.                                                                                                                                                    |
| Repository-knowledge checker | The command was initially missing (exit 127). After restoration, `scripts/check-repository-knowledge` reports two unresolved routes in `AGENTS.md`: `docs/reference/react.md` (line 125) and `docs/reference/third-party-sign-in-button-requirements.md` (line 176). Both files are deleted at `HEAD`. Negative probe `scripts/check-repository-knowledge ../outside.md` exited nonzero and reported `Out-of-repository path`.      |
| Focused Minitest             | Architecture-baseline, `PublicId`, and `Retainable` tests: **27 runs, 81 assertions, 0 failures/errors/skips**. Database-consistency length/nullability contract test: **4 runs, 45 assertions, 0 failures/errors/skips**.                                                                                                                                                                                                          |
| Full Rails Minitest          | `bin/rails test` — **3735 runs, 42140 assertions, 0 failures, 0 errors, 0 skips**. It ran with a process-local test-database list restricted to retained databases.                                                                                                                                                                                                                                                                 |
| Diff integrity               | `git diff --check` — **pass**. No database paths or encrypted credential paths were modified.                                                                                                                                                                                                                                                                                                                                       |

## Owner-contract stops and remaining findings

### DatabaseConsistency

`RAILS_ENV=test bundle exec database_consistency` runs with no configuration files and reports 24
`NullConstraintChecker` findings for `content_digest` on the 12 Publishing `EntryRevision` and 12
`EntryVersion` models. The output contains no Solid Queue finding; Solid Queue remains excluded from
this evaluation.

The existing C10 contract in `specs/database-consistency-remediation/spec.md` and the associated
cycle documentation explicitly retain create-only length/format validation.
`test/unit/database_consistency_length_nullability_test.rb` also verifies nil refusal at creation
while the database rejects a later null update. Adding presence validation solely to silence this
checker would change the accepted model contract. No validation, schema constraint, or data was
changed. An owner decision is required before changing C10; these 24 findings remain.

### i18n unused keys

The unused report is not a safe deletion list. `docs/backlog/2026-10-25-i18n-unused-keys.md`
requires tracing finite maps, runtime-built prefixes and Active Record translation lookups before
deletion. The 1250 entries include these namespaces and automatic lookup families. No translations
were removed, and no checker suppression was added. A source-reviewed cleanup is still required to
meet the zero-unused-key target.

### Historical secrets and repository navigation

The 247 Gitleaks findings are committed history, not current changes. Making an all-history scan
zero requires rewriting shared Git history. No rewrite was authorized, so this remains an owner
decision. The separate no-Git scan is unverified.

The repository-knowledge checker exposes the two dangling `AGENTS.md` routes above. They conflict
with the deleted documentation and current root instructions. No placeholder documents or weakened
router rules were introduced; this needs an owner decision about whether to restore the guidance or
update the router to the current surface set.

### Existing workflow environment

The existing `.github/workflows/ci.yml` edit was not made here. Its only remaining explicit retired
bucket name found is `OBJECT_STORAGE_BUCKET_AVATAR` at lines 183 and 405. The workflow also retains
base/core/warp/palm/tech URL names associated with RP cells removed from Press (lines 209–226,
239–254); those may be consumed through dynamic client/host registries, so this run did not classify
them as unused or change them. The broader environment/configuration inventory remains deferred by
the work order. Other direct-reference scans were not used to remove runtime or action inputs.

## Herb comparison (read-only)

- ERB-Lint 0.9.0 uses the repository's `.erb_lint.yml`: **16 enabled linters** over 855 files in
  about 1.3 seconds, with zero errors.
- Herb 0.11.2 has a Ruby-native parser/compiler, project analyzer, **148 enabled linter rules** and
  editor support through its language server. Its Rails integration supports Rails 8.2; the local
  `.herb.yml` is version 0.11.1 and leaves `framework` unset, so Herb reports that it assumes plain
  Ruby templates instead of Action View.
- `bundle exec herb analyze .` checked 58 configured files in 2.53 seconds and found one dynamic
  attribute-name security issue in `app/views/shared/ui/_button.html.erb`.
  `bundle exec herb lint app/views` reported 11 errors across 9 files: 3 dynamic-attribute findings
  and 8 `erb-no-unused-expressions` findings for `page_title` calls. `ApplicationHelper#page_title`
  writes `content_for(:page_title)`, so those calls are intentional Rails side effects. ERB-Lint and
  Herb did not inspect equivalent file sets, so their timings are not a speed comparison. Herb is
  not adopted by this work.

## Final status

- Static checks with zero findings: RuboCop, frozen-string checks, ERB-Lint, i18n missing, Brakeman,
  actionlint, Bundler audit, JavaScript audit, JavaScript format/lint/typecheck, aggregate
  `bun run check`, and the production Vite build.
- Remaining: 24 DatabaseConsistency findings under C10; 1250 unused locale entries awaiting source
  review; 247 historical secret findings; two missing repository-knowledge routes; and the
  uncompleted no-Git Gitleaks scan.
- Rails tests: **3735/3735 passed**. No schema rebuild was needed or run.
- Uncommitted work remains. No commit, push, deployment, CI workflow edit, credentials edit, or
  database migration was made.

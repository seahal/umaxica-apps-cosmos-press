# Rails Public and Protected Method Coverage

## Worktree

- HEAD: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`
- The workspace already contained about 4,400 uncommitted changes from earlier work. They were
  preserved.
- This coverage task changed tests and this evidence file; it did not change Rails implementation,
  CI, or coverage thresholds.

## Measurement

The final full Minitest run completed **3,690 tests and 42,368 assertions, with 0 failures, 0
errors, and 0 skips**.

A Ruby `Coverage` preloader started before Rails boot, then the regular SimpleCov test setup wrote
the report under `/tmp/codex-public-coverage`. A temporary Rails runner inventoried loaded Ruby
methods by source location and visibility. The audited denominator was 1,287 public or protected
methods: 1,258 public and 29 protected. This includes four public RuboCop cop callbacks whose
visibility was not discoverable from the Rails eager-load inventory; source inspection classified
and counted them, and all four were covered. **1,277/1,287 methods were covered (99.22%); 10
remained uncovered.**

The default SimpleCov totals for the same run were 94.25% line, 64.73% branch, and 94.16% all-method
coverage. The existing thresholds remain 98%, 93%, and 97%; SimpleCov therefore exited with its
coverage failure after all Minitest cases passed. The private-excluded method audit is separate from
those all-method totals.

## Tests Added or Extended

- Added calls for untested value, model, serializer, adapter, service, and query entry points,
  including sign-in sequence values, step-up values, JWT profiles, publishing results, OIDC lookup
  status, encryption-key providers, and route aliases.
- Extended Browser RP tests for session helpers, operator helpers, policy-rule resolution,
  credential refusal behavior, class-level filter restrictions, and OIDC SSO authentication.
- Added Edit helper, sign-out, verification, and publishing authority response tests. Publishing
  management concern actions use a dedicated test controller and an unavailable authority response;
  no production authorization path was changed.
- Added outbound-email suspension and JWT anomaly reporting tests that verify delivery suppression
  and diagnostic data handling.
- Added an isolated `ArchitectureBaseline.write` test that redirects output paths to temporary files
  and restores the original constants.

Focused Rails tests covering the added cases passed. RuboCop passed on the 13 changed test files.

## Remaining Ten Methods

- Eight public actions in the Edit publishing API controllers (`entries`, `publications`, and
  `archives`) are not invoked. `PublishingAuthorityApiEndpoint#authenticate_publishing_caller!`
  currently returns an explicit unavailable response before any management query or mutation, and
  the existing API test verifies this fail-closed contract. The action bodies were not reached by
  bypassing that boundary.
- `JumpRtIssuer#call` is not reachable in Press: the Press tests verify that it has no accepted Jump
  RT signing namespace and reject all supplied namespaces before issuance.
- `Actor::StepUp.null` raises `NameError: uninitialized constant Actor::NULL` when called. No test
  was added to encode this failure as a valid contract, and implementation changes were outside this
  task.

The target is therefore not yet 100%. The remaining methods require either an owner-approved
authenticated Publishing API contract, a Press-owned Jump RT issuer identity, or a correction to
`Actor::StepUp.null`.

## Commands

```bash
POSTGRESQL_TEST_PREPARE_DATABASES=test_primary_db,test_publishing_db,test_rp_edit_org_db,test_chronicle_db,test_queue_db,test_storage_db \
COVERAGE=true RAILS_ENV=test RUBYOPT=-r/tmp/codex_simplecov_boot.rb PARALLEL_WORKERS=1 \
bin/rails test

bin/rubocop \
  test/adapters/oidc_op_jwks_client_transport_test.rb \
  test/services/outbound_channel_suspension_test.rb \
  test/lib/realm_identifier_encryption_key_provider_test.rb \
  test/services/jit_security_jwt_anomaly_reporter_test.rb \
  test/controllers/concerns/surface_route_alias_helper_test.rb \
  test/models/public_method_contract_values_test.rb \
  test/mailers/outbound_email_suspension_interceptor_test.rb \
  test/controllers/concerns/browser_rp_authentication_test.rb \
  test/controllers/edit/org/sign/outs_controller_test.rb \
  test/controllers/edit/org/application_controller_helper_methods_test.rb \
  test/controllers/edit/org/publishing/management_actions_coverage_test.rb \
  test/controllers/edit/org/verifications_controller_test.rb \
  test/tooling/architecture_baseline_test.rb
```

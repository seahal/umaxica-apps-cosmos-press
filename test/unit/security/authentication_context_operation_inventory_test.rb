# typed: false
# frozen_string_literal: true

require "test_helper"

# Restitution WU-A6 (AC-41): the authentication-context layer is operation-blind.
# Apply each zero-argument public policy predicate through Action Policy's real
# pre-check under normal and standby token claims, and require the same outcome.
# An unrecognised context must deny before any ordinary rule can allow it.
#
# Inventory note: this guard enumerates the concrete policy classes under
# app/policies and their public rule predicates. A policy keeps ordinary deny
# semantics under both contexts; the sensitive-operation boundary is that
# operation's Step-Up gate, never the context layer.
class AuthenticationContextOperationInventoryTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  # The authorization engine receives this verified request context explicitly.
  CONTEXTS_UNDER_COMPARISON = {
    normal: -> { AuthenticationContextValue.normal },
    standby: -> { AuthenticationContextValue.standby },
  }.freeze
  test "every declared policy operation decides identically for normal and standby sessions" do
    compared = 0

    policy_classes.each do |policy_class|
      declared_rules(policy_class).each do |rule|
        outcomes =
          CONTEXTS_UNDER_COMPARISON.to_h do |name, context_factory|
            authentication_context = context_factory.call
            token_claims = {
              "scope" => "authenticated domain:operator read:org write:org",
              AuthenticationContextValue::CLAIM => authentication_context.key,
            }

            principal = RpEditOrgPrincipal.new(id: 381, disabled_at: nil)
            policy = policy_class.new(
              record_for(policy_class, principal), user: principal, access_token_claims: token_claims,
            )
            outcome =
              begin
                !!policy.apply(rule)
              rescue GovernanceUnavailableError
                # An unavailable authoritative owner is a closed outcome, never a permission.
                :governance_unavailable
              end
            [name, outcome]
          end

        assert_equal outcomes.fetch(:normal), outcomes.fetch(:standby),
                     "#{policy_class}##{rule} must not differ by authentication context"

        compared += 1
      end
    end

    assert_operator compared, :>, 0, "the policy inventory must not be empty"
  end

  test "an unrecognised authentication context denies every declared operation" do
    token_claims = {
      "scope" => "authenticated domain:operator read:org write:org",
      AuthenticationContextValue::CLAIM => "elevated",
    }

    policy_classes.each do |policy_class|
      declared_rules(policy_class).each do |rule|
        principal = RpEditOrgPrincipal.new(id: 381, disabled_at: nil)
        policy = policy_class.new(
          record_for(policy_class, principal), user: principal, access_token_claims: token_claims,
        )

        assert_not policy.apply(rule),
                   "#{policy_class}##{rule} must fail closed for an unrecognised context"
      end
    end
  end

  test "the one session capability is step-up, and the named scope privileges stay closed" do
    assert_equal ["step_up"], AuthenticationContextValue::REGISTRY.fetch("normal").capabilities
    assert_empty AuthenticationContextValue::REGISTRY.fetch("standby").capabilities
    assert_equal %w(read:org write:org read:self write:self),
                 AuthenticationContextValue::CAPABILITY_NAMED_SCOPES
    # A standby session is never issued more than the same actor's normal claims.
    operator_scopes = %w(authenticated domain:operator read:org write:org)

    assert_equal AuthenticationContextValue.normal.constrain_scopes(operator_scopes),
                 AuthenticationContextValue.standby.constrain_scopes(operator_scopes)
  end

  test "publishing requires governance in normal and standby and denies unknown contexts" do
    principal = RpEditOrgPrincipal.new(disabled_at: nil)
    entry = Publishing::Docs::Org::Entry.new

    [AuthenticationContextValue::NORMAL_KEY, AuthenticationContextValue::STANDBY_KEY].each do |context|
      claims = {
        "scope" => "authenticated domain:operator read:org write:org",
        AuthenticationContextValue::CLAIM => context,
      }
      policy = PublishingEntryPolicy.new(entry, user: principal, access_token_claims: claims)

      assert_raises(GovernanceUnavailableError) { policy.apply(:create?) }
    end

    assert_not PublishingEntryPolicy.new(
      entry, user: principal, access_token_claims: { AuthenticationContextValue::CLAIM => "elevated" },
    ).apply(:create?)
  end

  private

  def record_for(policy_class, principal)
    if policy_class == RpPrincipalPolicy
      principal
    elsif policy_class == PublishingEntryPolicy
      Publishing::Docs::Org::Entry.new(locale: "en")
    elsif policy_class == PublishingRemoteResultPolicy
      PublishingAuthorityClient::Result.new(status: :ok, data: {}, errors: nil)
    end
  end

  def policy_classes
    Rails.application.eager_load!
    @policy_classes ||= ApplicationPolicy.descendants.select { |klass| klass.is_a?(Class) }
      .reject { |klass| klass.name.start_with?("Test") }.sort_by(&:name)
  end

  def declared_rules(policy_class)
    policy_class.ancestors
      .take_while { |ancestor| ancestor != ApplicationPolicy.superclass }
      .flat_map do |ancestor|
        ancestor.public_instance_methods(false).select do |method_name|
          method_name.to_s.end_with?("?") && ancestor.instance_method(method_name).arity.zero? &&
            method_name != :deny_capability_restricted_context
        end
      end.uniq.sort
  end
end

# typed: false
# frozen_string_literal: true

require "test_helper"

class ActorContextTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    Actor.reset
  end

  teardown do
    Actor.reset
  end

  test "defaults for unauthenticated state" do
    assert_equal Unauthenticated.instance, Actor.actor
    assert_equal :unauthenticated, Actor.actor_type
    assert_predicate Actor, :unauthenticated?
    assert_not Actor.authenticated?
    assert_not Actor.signed_in?
    assert_not Actor.signed_up?
    assert_nil Actor.client
    assert_nil Actor.operator
    assert_equal Actor::Authentication::NULL, Actor.authn
    assert_equal Actor::Configuration::NULL, Actor.configuration
  end

  test "setting client actor" do
    user = RpEditOrgPrincipal.new(id: 123)
    Actor.actor = user
    Actor.actor_type = :client

    assert_equal user, Actor.actor
    assert_equal :client, Actor.actor_type
    assert_predicate Actor, :client?
    assert_predicate Actor, :authenticated?
    assert_predicate Actor, :signed_in?
    assert_predicate Actor, :signed_up?
    assert_equal user, Actor.client
    assert_not Actor.unauthenticated?
  end

  test "signed_up is false for authenticated actor without persisted identity" do
    Actor.actor = RpEditOrgPrincipal.new
    Actor.actor_type = :client

    assert_predicate Actor, :signed_in?
    assert_not Actor.signed_up?
  end

  test "authentication null object is safe for guests" do
    assert_predicate Actor.authn, :null?
    assert_nil Actor.authn.login_public_id
    assert_equal [], Actor.authn.amr
    assert_not Actor.authn.verified?
  end

  test "configuration null object is safe for guests" do
    assert_predicate Actor.configuration, :null?
    assert_predicate Actor.configuration.anything, :blank?
    assert_not Actor.configuration.anything.enabled?
    assert_equal "", Actor.configuration.anything.deeply.nested.to_s
  end

  test "configuration is an immutable request context box" do
    configuration = Actor::Configuration.new(feature: true)

    assert configuration.feature
    assert_equal({ feature: true }, configuration.to_h)
    assert_predicate configuration, :frozen?

    updated = configuration.with(region: "jp")

    assert_equal({ feature: true }, configuration.to_h)
    assert_equal({ feature: true, region: "jp" }, updated.to_h)
    assert_not_same configuration, updated
  end

  test "configuration supports typed sign namespace values" do
    sign_configuration =
      Actor::SignConfiguration.new(
        value: "required",
        enabled: true,
        mode: "strict",
      )

    Actor.configuration = Actor::Configuration.new(sign: sign_configuration)

    assert_equal "required", Actor.configuration.sign.value
    assert Actor.configuration.sign.enabled
    assert_equal "strict", Actor.configuration.sign.mode
  end

  test "setting staff actor" do
    staff = RpEditOrgPrincipal.new(id: 456)
    Actor.actor = staff
    Actor.actor_type = :operator

    assert_equal staff, Actor.actor
    assert_equal :operator, Actor.actor_type
    assert_predicate Actor, :operator?
    assert_predicate Actor, :authenticated?
    assert_equal staff, Actor.operator
  end

  test "preference authority is explicitly unavailable rather than replaced by defaults" do
    assert_raises(GovernanceUnavailableError) { Actor.preferences }
    assert_raises(GovernanceUnavailableError) { Actor.preferences = Object.new }
    assert_raises(GovernanceUnavailableError) { Actor.install_context!(preferences: Object.new) }
    assert_raises(GovernanceUnavailableError) { ActorValuesContext.empty.preferences }
    assert_raises(GovernanceUnavailableError) { ActorValuesContext.empty.with(preferences: nil) }
    assert_raises(GovernanceUnavailableError) {
      ActorValuesContext.new(**ActorValuesContext.empty.to_h, preferences: nil)
    }
  end
end

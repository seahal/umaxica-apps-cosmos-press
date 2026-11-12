# frozen_string_literal: true

require "test_helper"

class ActorValuesContextVisitorPredicateTest < ActiveSupport::TestCase
  test "anonymous aliases the unauthenticated actor role" do
    assert_predicate ActorValuesContext.empty, :anonymous?
    assert_not_predicate ActorValuesContext.empty.with(actor_type: :client), :anonymous?
  end

  test "retired visitor actor type is rejected while client and operator roles remain explicit" do
    assert_raises(ArgumentError) { ActorValuesContext.empty.with(actor_type: :visitor) }
    assert_predicate ActorValuesContext.empty.with(actor_type: :client), :client?
    assert_predicate ActorValuesContext.empty.with(actor_type: :operator), :operator?
  end
end

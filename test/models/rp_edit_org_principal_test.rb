# frozen_string_literal: true

require "test_helper"

class RpEditOrgPrincipalTest < ActiveSupport::TestCase
  test "local principal exposes the operator policy and disabled state" do
    principal = RpEditOrgPrincipal.new(id: 123)

    assert_equal RpPrincipalPolicy, principal.policy_class
    assert_equal :operator, principal.actor_type
    assert_not_predicate principal, :deactivated?
    assert_predicate RpEditOrgPrincipal.new(disabled_at: Time.current), :deactivated?
  end

  test "public_id is a fixed 21-character NanoID" do
    assert_public_id_fixed_length(::RpEditOrgPrincipal)
  end
end

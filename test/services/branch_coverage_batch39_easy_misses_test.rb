# typed: false
# frozen_string_literal: true

require "test_helper"

# Mass-cover remaining 1-2 miss service/value/lib arms to clear the 90% branch floor.
class BranchCoverageBatch39EasyMissesTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "SignInSequenceCarrier finish! blank sequence" do
    carrier = SignInSequenceCarrier.new({}, surface: :app)
    result = carrier.finish!(terminal_state: "done")

    assert_kind_of SignInSequence, result
    assert_predicate result.payload, :blank?
  end

  test "RedirectsJumpGatewayUrl origin validation arms" do
    assert_raises(ArgumentError) { RedirectsJumpGatewayUrl.call(gateway_origin: "://bad") }
    assert_raises(ArgumentError) { RedirectsJumpGatewayUrl.call(gateway_origin: "http://example.com") }
  end
end

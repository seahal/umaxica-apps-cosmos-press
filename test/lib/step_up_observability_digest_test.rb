# frozen_string_literal: true

require "test_helper"

class StepUpObservabilityDigestTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "public references are fixed length and domain separated" do
    ceremony = StepUpObservabilityDigest.ceremony_ref("transaction-1")
    session = StepUpObservabilityDigest.session_ref("transaction-1")
    jump = StepUpObservabilityDigest.jump_jti_ref("transaction-1")

    assert_match(/\A[0-9a-f]{32}\z/, ceremony)
    assert_match(/\A[0-9a-f]{32}\z/, session)
    assert_match(/\A[0-9a-f]{32}\z/, jump)
    assert_equal 3, [ceremony, session, jump].uniq.length
    assert_raises(ArgumentError) { StepUpObservabilityDigest.ceremony_ref(" ") }
  end
end

# typed: false
# frozen_string_literal: true

require "test_helper"

# Unit tops for still-cold raise/return arms needed to clear the 90% branch floor.
class BranchCoverageBatch32ThresholdPushTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "Health ok? status string arms" do
    ok = Health::CheckResult.new(check: :liveness, status: :ok, surface: "app")
    unready = Health::CheckResult.new(check: :liveness, status: :unready, surface: "app")

    assert_predicate ok, :ok?
    assert_not unready.ok?
    assert_equal "ok", ok.as_public_json[:status]
    assert_equal "unavailable", unready.as_public_json[:status]
  end

  test "ChainSeal verify rescue ArgumentError path via bad public key type" do
    assert_raises(ChainSeal::FormatError, ChainSeal::VerificationError) do
      ChainSeal.verify(payload: { a: 1 }, compact: "not-a-seal", public_key: "nope")
    end
  end
end
